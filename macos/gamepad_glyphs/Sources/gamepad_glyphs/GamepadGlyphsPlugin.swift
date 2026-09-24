import Cocoa
import FlutterMacOS
import GameController

private let controllerDeadZone: Float = 0.1

public class GamepadGlyphsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var detectMouse = false
  private var detectTouch = false
  private var localEventMonitor: Any?
  private var controllerConnectObserver: NSObjectProtocol?
  private var controllerDisconnectObserver: NSObjectProtocol?
  private var controllerElementValues: [ObjectIdentifier: [Float]] = [:]

  deinit {
    stopControllerMonitoring()
    stopLocalEventMonitoring()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "gamepad_glyphs",
      binaryMessenger: registrar.messenger
    )
    let eventChannel = FlutterEventChannel(
      name: "gamepad_glyphs/input_events",
      binaryMessenger: registrar.messenger
    )
    let instance = GamepadGlyphsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    let options = arguments as? [String: Any]
    detectMouse = options?["detectMouse"] as? Bool ?? false
    detectTouch = options?["detectTouch"] as? Bool ?? false
    eventSink = events
    startControllerMonitoring()
    startLocalEventMonitoring()
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    detectMouse = false
    detectTouch = false
    stopControllerMonitoring()
    stopLocalEventMonitoring()
    return nil
  }

  private func startControllerMonitoring() {
    stopControllerMonitoring()
    let center = NotificationCenter.default
    controllerConnectObserver = center.addObserver(
      forName: Notification.Name.GCControllerDidConnect,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let controller = notification.object as? GCController else { return }
      self?.configure(controller)
    }
    controllerDisconnectObserver = center.addObserver(
      forName: Notification.Name.GCControllerDidDisconnect,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let controller = notification.object as? GCController else { return }
      self?.forget(controller)
    }
    GCController.controllers().forEach(configure)
  }

  private func stopControllerMonitoring() {
    let center = NotificationCenter.default
    if let observer = controllerConnectObserver { center.removeObserver(observer) }
    if let observer = controllerDisconnectObserver { center.removeObserver(observer) }
    controllerConnectObserver = nil
    controllerDisconnectObserver = nil

    for controller in GCController.controllers() {
      controller.extendedGamepad?.valueChangedHandler = nil
      controller.microGamepad?.valueChangedHandler = nil
    }
    controllerElementValues.removeAll()
  }

  private func configure(_ controller: GCController) {
    if let profile = controller.extendedGamepad {
      prime(profile)
      profile.valueChangedHandler = { [weak self, weak controller] _, element in
        self?.handleControllerElement(element, controller: controller)
      }
    } else if let profile = controller.microGamepad {
      prime(profile)
      profile.valueChangedHandler = { [weak self, weak controller] _, element in
        self?.handleControllerElement(element, controller: controller)
      }
    }
  }

  private func profile(for controller: GCController) -> GCPhysicalInputProfile? {
    if let profile = controller.extendedGamepad { return profile }
    return controller.microGamepad
  }

  private func forget(_ controller: GCController) {
    guard let profile = profile(for: controller) else { return }
    for element in profile.allElements {
      controllerElementValues.removeValue(forKey: ObjectIdentifier(element))
    }
  }

  private func prime(_ profile: GCPhysicalInputProfile) {
    for element in profile.allElements {
      if let values = values(for: element) {
        controllerElementValues[ObjectIdentifier(element)] = values
      }
    }
  }

  private func values(for element: GCControllerElement) -> [Float]? {
    if let button = element as? GCControllerButtonInput {
      return [button.value]
    }
    if let axis = element as? GCControllerAxisInput {
      return [axis.value]
    }
    if let pad = element as? GCControllerDirectionPad {
      return [pad.xAxis.value, pad.yAxis.value]
    }
    return nil
  }

  private func handleControllerElement(
    _ element: GCControllerElement,
    controller: GCController?
  ) {
    guard let current = values(for: element) else { return }
    let identifier = ObjectIdentifier(element)
    guard let baseline = controllerElementValues[identifier],
      baseline.count == current.count else {
      controllerElementValues[identifier] = current
      return
    }

    if let button = element as? GCControllerButtonInput {
      controllerElementValues[identifier] = current
      if button.value > controllerDeadZone && baseline[0] <= controllerDeadZone {
        emitController(controller)
      }
      return
    }

    if zip(baseline, current).contains(where: {
      abs($0.0 - $0.1) > controllerDeadZone
    }) {
      controllerElementValues[identifier] = current
      emitController(controller)
    }
  }

  private func emitController(_ controller: GCController?) {
    var event: [String: Any] = [
      "vendorId": NSNull(),
      "productId": NSNull(),
      "kind": "gamepad",
    ]
    if let controller {
      event["productCategory"] = controller.productCategory
    }
    eventSink?(event)
  }

  private func startLocalEventMonitoring() {
    stopLocalEventMonitoring()

    var eventMask: NSEvent.EventTypeMask = [.keyDown]
    if detectMouse {
      eventMask.insert(.leftMouseDown)
      eventMask.insert(.rightMouseDown)
      eventMask.insert(.otherMouseDown)
      eventMask.insert(.mouseMoved)
      eventMask.insert(.scrollWheel)
    }
    if detectTouch {
      eventMask.insert(.directTouch)
      eventMask.insert(.gesture)
    }

    localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) {
      [weak self] event in
      switch event.type {
      case .keyDown:
        self?.emit(kind: "keyboard")
      case .leftMouseDown, .rightMouseDown, .otherMouseDown,
           .mouseMoved, .scrollWheel:
        if self?.detectMouse == true { self?.emit(kind: "mouse") }
      case .directTouch, .gesture:
        if self?.detectTouch == true { self?.emit(kind: "touch") }
      default:
        break
      }
      return event
    }
  }

  private func stopLocalEventMonitoring() {
    if let monitor = localEventMonitor {
      NSEvent.removeMonitor(monitor)
      localEventMonitor = nil
    }
  }

  private func emit(kind: String) {
    eventSink?([
      "vendorId": NSNull(),
      "productId": NSNull(),
      "kind": kind,
    ])
  }
}
