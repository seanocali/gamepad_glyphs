import Cocoa
import FlutterMacOS
import IOKit.hid

public class GamepadGlyphsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var hidManager: IOHIDManager?

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
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
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
    let usage = IOHIDElementGetUsage(element)

    let keyboard = usagePage == UInt32(kHIDPage_KeyboardOrKeypad)
    let controller = usagePage == UInt32(kHIDPage_GenericDesktop) ||
      usagePage == UInt32(kHIDPage_Button)
    guard keyboard || controller else { return }

    if keyboard {
      sink(["vendorId": NSNull(), "productId": NSNull()])
      return
    }

    // Ignore generic desktop pointer/mouse events. Gamepad axes and buttons
    // use the gamepad/joystick usages or the button usage page.
    if usagePage == UInt32(kHIDPage_GenericDesktop) &&
      usage != UInt32(kHIDUsage_GD_GamePad) &&
      usage != UInt32(kHIDUsage_GD_Joystick) &&
      usage != UInt32(kHIDUsage_GD_X) &&
      usage != UInt32(kHIDUsage_GD_Y) &&
      usage != UInt32(kHIDUsage_GD_Z) &&
      usage != UInt32(kHIDUsage_GD_Rx) &&
      usage != UInt32(kHIDUsage_GD_Ry) &&
      usage != UInt32(kHIDUsage_GD_Rz) {
      return
    }

    let device = IOHIDElementGetDevice(element)
    let vendorId = propertyInt(device, key: kIOHIDVendorIDKey)
    let productId = propertyInt(device, key: kIOHIDProductIDKey)
    sink([
      "vendorId": vendorId.map { $0 as Any } ?? NSNull(),
      "productId": productId.map { $0 as Any } ?? NSNull(),
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
