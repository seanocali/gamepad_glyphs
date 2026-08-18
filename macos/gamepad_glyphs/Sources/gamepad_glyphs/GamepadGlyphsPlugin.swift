import Cocoa
import FlutterMacOS
import IOKit.hid

public class GamepadGlyphsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var hidManager: IOHIDManager?
  private var detectMouse = false
  private var detectTouch = false

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
    IOHIDManagerRegisterInputValueCallback(manager, hidInputValueCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
    IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
    IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
  }

  private func handleHIDValue(_ value: IOHIDValue) {
    guard let sink = eventSink else { return }
    let element = IOHIDValueGetElement(value)
    let usagePage = IOHIDElementGetUsagePage(element)

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
      sink(["vendorId": NSNull(), "productId": NSNull(), "kind": kind])
      return
    }

    let vendorId = propertyInt(device, key: kIOHIDVendorIDKey)
    let productId = propertyInt(device, key: kIOHIDProductIDKey)
    sink([
      "vendorId": vendorId.map { $0 as Any } ?? NSNull(),
      "productId": productId.map { $0 as Any } ?? NSNull(),
      "kind": kind,
    ])
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
  guard let context, let value else { return }
  let plugin = Unmanaged<GamepadGlyphsPlugin>.fromOpaque(context).takeUnretainedValue()
  plugin.handleHIDValue(value)
}
