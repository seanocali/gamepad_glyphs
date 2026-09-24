import Cocoa
import FlutterMacOS
import IOKit.hid

private let controllerHIDUsages: Set<UInt32> = [
  0x30, // X
  0x31, // Y
  0x32, // Z
  0x33, // Rx
  0x34, // Ry
  0x35, // Rz
  0x36, // Slider
  0x37, // Dial
  0x38, // Wheel
  0x39, // Hat switch
]

func controllerHIDValueMoved(
  from baseline: Int,
  to current: Int,
  minimum: Int,
  maximum: Int
) -> Bool {
  let baselineValue = Int64(baseline)
  let currentValue = Int64(current)
  let travel = max(
    abs(Int64(maximum) - baselineValue),
    abs(baselineValue - Int64(minimum))
  )
  let deadZone = max(Int64(1), travel / 10)
  return abs(currentValue - baselineValue) > deadZone
}

private struct HIDElementKey: Hashable {
  let device: UInt64
  let element: IOHIDElementCookie
}

public class GamepadGlyphsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var hidManager: IOHIDManager?
  private var detectMouse = false
  private var detectTouch = false
  private var controllerElementValues: [HIDElementKey: Int] = [:]

  deinit {
    if let manager = hidManager {
      IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
      IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "gamepad_glyphs", binaryMessenger: registrar.messenger)
    let eventChannel = FlutterEventChannel(name: "gamepad_glyphs/input_events", binaryMessenger: registrar.messenger)
    let instance = GamepadGlyphsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
    instance.startHIDMonitoring()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    let options = arguments as? [String: Any]
    detectMouse = options?["detectMouse"] as? Bool ?? false
    detectTouch = options?["detectTouch"] as? Bool ?? false
    eventSink = events
    primeConnectedControllers()
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    detectMouse = false
    detectTouch = false
    return nil
  }

  private func startHIDMonitoring() {
    let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    hidManager = manager
    let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
    IOHIDManagerRegisterDeviceMatchingCallback(manager, hidDeviceMatchedCallback, context)
    IOHIDManagerRegisterInputValueCallback(manager, hidInputValueCallback, context)
    IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
    IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    primeConnectedControllers()
  }

  private func primeConnectedControllers() {
    guard let manager = hidManager,
      let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
      return
    }
    for device in devices { primeController(device) }
  }

fileprivate func primeController(_ device: IOHIDDevice) {
    let primaryUsagePage = propertyInt(device, key: kIOHIDPrimaryUsagePageKey)
    let primaryUsage = propertyInt(device, key: kIOHIDPrimaryUsageKey)
    guard primaryUsagePage == Int(kHIDPage_GenericDesktop) &&
      (primaryUsage == Int(kHIDUsage_GD_GamePad) ||
       primaryUsage == Int(kHIDUsage_GD_Joystick)),
      let elements = IOHIDDeviceCopyMatchingElements(
        device,
        nil,
        IOOptionBits(kIOHIDOptionsTypeNone)
      ) as? [IOHIDElement] else {
      return
    }

    for element in elements {
      let usagePage = IOHIDElementGetUsagePage(element)
      let usage = IOHIDElementGetUsage(element)
      let button = usagePage == UInt32(kHIDPage_Button)
      let axis = usagePage == UInt32(kHIDPage_GenericDesktop) &&
        controllerHIDUsages.contains(usage)
      guard button || axis else { continue }

      let valuePointer = UnsafeMutablePointer<Unmanaged<IOHIDValue>>.allocate(capacity: 1)
      defer { valuePointer.deallocate() }
      guard IOHIDDeviceGetValue(device, element, valuePointer) == kIOReturnSuccess else {
        continue
      }
      let value = valuePointer.pointee.takeUnretainedValue()
      controllerElementValues[elementKey(device: device, element: element)] =
        IOHIDValueGetIntegerValue(value)
    }
  }

  fileprivate func handleHIDValue(_ value: IOHIDValue) {
    let element = IOHIDValueGetElement(value)
    let usagePage = IOHIDElementGetUsagePage(element)
    let usage = IOHIDElementGetUsage(element)
    let integerValue = IOHIDValueGetIntegerValue(value)

    let keyboard = usagePage == UInt32(kHIDPage_KeyboardOrKeypad)
    let device = IOHIDElementGetDevice(element)
    let primaryUsagePage = propertyInt(device, key: kIOHIDPrimaryUsagePageKey)
    let primaryUsage = propertyInt(device, key: kIOHIDPrimaryUsageKey)
    let controller = primaryUsagePage == Int(kHIDPage_GenericDesktop) &&
      (primaryUsage == Int(kHIDUsage_GD_GamePad) ||
       primaryUsage == Int(kHIDUsage_GD_Joystick))
    let mouse = primaryUsagePage == Int(kHIDPage_GenericDesktop) &&
      primaryUsage == Int(kHIDUsage_GD_Mouse)
    let touch = primaryUsagePage == 0x0D &&
      (primaryUsage == 0x04 || primaryUsage == 0x05)
    guard keyboard || controller || (detectMouse && mouse) ||
      (detectTouch && touch) else { return }
    let kind = keyboard ? "keyboard" : controller ? "gamepad" : mouse ? "mouse" : "touch"

    if keyboard {
      if integerValue != 0 {
        eventSink?(["vendorId": NSNull(), "productId": NSNull(), "kind": kind])
      }
      return
    }

    if controller && !controllerElementIsActive(
      device: device,
      element: element,
      usagePage: usagePage,
      usage: usage,
      value: integerValue
    ) {
      return
    }

    let vendorId = propertyInt(device, key: kIOHIDVendorIDKey)
    let productId = propertyInt(device, key: kIOHIDProductIDKey)
    eventSink?([
      "vendorId": vendorId.map { $0 as Any } ?? NSNull(),
      "productId": productId.map { $0 as Any } ?? NSNull(),
      "kind": kind,
    ])
  }

  private func controllerElementIsActive(
    device: IOHIDDevice,
    element: IOHIDElement,
    usagePage: UInt32,
    usage: UInt32,
    value: Int
  ) -> Bool {
    let button = usagePage == UInt32(kHIDPage_Button)
    let axis = usagePage == UInt32(kHIDPage_GenericDesktop) &&
      controllerHIDUsages.contains(usage)
    guard button || axis else { return false }

    let key = elementKey(device: device, element: element)
    guard let baseline = controllerElementValues[key] else {
      controllerElementValues[key] = value
      return false
    }

    if button {
      controllerElementValues[key] = value
      return value != 0 && baseline == 0
    }

    let active = controllerHIDValueMoved(
      from: baseline,
      to: value,
      minimum: IOHIDElementGetLogicalMin(element),
      maximum: IOHIDElementGetLogicalMax(element)
    )
    if active { controllerElementValues[key] = value }
    return active
  }

  private func elementKey(
    device: IOHIDDevice,
    element: IOHIDElement
  ) -> HIDElementKey {
    HIDElementKey(
      device: UInt64(IOHIDDeviceGetService(device)),
      element: IOHIDElementGetCookie(element)
    )
  }

  private func propertyInt(_ device: IOHIDDevice, key: String) -> Int? {
    guard let value = IOHIDDeviceGetProperty(device, key as CFString) else { return nil }
    var number: Int32 = 0
    if CFGetTypeID(value) == CFNumberGetTypeID() {
      CFNumberGetValue((value as! CFNumber), .sInt32Type, &number)
      return Int(number)
    }
    return nil
  }
}

private let hidInputValueCallback: IOHIDValueCallback = { context, _, _, value in
  guard let context else { return }
  let plugin = Unmanaged<GamepadGlyphsPlugin>.fromOpaque(context).takeUnretainedValue()
  plugin.handleHIDValue(value)
}

private let hidDeviceMatchedCallback: IOHIDDeviceCallback = { context, _, _, device in
  guard let context else { return }
  let plugin = Unmanaged<GamepadGlyphsPlugin>.fromOpaque(context).takeUnretainedValue()
  plugin.primeController(device)
}
