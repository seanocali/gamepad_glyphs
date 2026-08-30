import Flutter
import GameController
import UIKit

let controllerDeadZone: Float = 0.1

func controllerValueMoved(from baseline: Float, to current: Float) -> Bool {
  abs(current - baseline) > controllerDeadZone
}

public class GamepadGlyphsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private weak var viewController: UIViewController?
  private var detectMouse = false
  private var detectTouch = false
  private var controllerConnectObserver: NSObjectProtocol?
  private var controllerDisconnectObserver: NSObjectProtocol?
  private var keyboardConnectObserver: NSObjectProtocol?
  private var touchRecognizer: UITapGestureRecognizer?
  private var hoverRecognizer: UIGestureRecognizer?
  private var controllerElementValues: [ObjectIdentifier: [Float]] = [:]

  public override convenience init() {
    self.init(viewController: nil)
  }

  init(viewController: UIViewController?) {
    self.viewController = viewController
    super.init()
  }

  deinit {
    stopMonitoring()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "gamepad_glyphs",
      binaryMessenger: registrar.messenger()
    )
    let eventChannel = FlutterEventChannel(
      name: "gamepad_glyphs/input_events",
      binaryMessenger: registrar.messenger()
    )
    let instance = GamepadGlyphsPlugin(viewController: registrar.viewController)
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
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
    startMonitoring()
    updatePointerRecognizers()
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    detectMouse = false
    detectTouch = false
    stopMonitoring()
    updatePointerRecognizers()
    return nil
  }

  private func emit(kind: String, controller: GCController? = nil) {
    var event: [String: Any] = [
      "vendorId": NSNull(),
      "productId": NSNull(),
      "kind": kind,
    ]
    if #available(iOS 13.0, *), let controller {
      event["productCategory"] = controller.productCategory
    }
    eventSink?(event)
  }

  private func startMonitoring() {
    stopMonitoring()
    let center = NotificationCenter.default
    controllerConnectObserver = center.addObserver(
      forName: .GCControllerDidConnect,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let controller = notification.object as? GCController else { return }
      self?.configure(controller)
    }
    controllerDisconnectObserver = center.addObserver(
      forName: .GCControllerDidDisconnect,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let controller = notification.object as? GCController else { return }
      self?.forget(controller)
    }
    GCController.controllers().forEach(configure)

    if #available(iOS 14.0, *) {
      keyboardConnectObserver = center.addObserver(
        forName: .GCKeyboardDidConnect,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.configureKeyboard()
      }
      configureKeyboard()
    }
  }

  private func stopMonitoring() {
    let center = NotificationCenter.default
    for observer in [
      controllerConnectObserver,
      controllerDisconnectObserver,
      keyboardConnectObserver,
    ] {
      if let observer { center.removeObserver(observer) }
    }
    controllerConnectObserver = nil
    controllerDisconnectObserver = nil
    keyboardConnectObserver = nil

    for controller in GCController.controllers() {
      controller.extendedGamepad?.valueChangedHandler = nil
      controller.microGamepad?.valueChangedHandler = nil
      controller.gamepad?.valueChangedHandler = nil
    }
    if #available(iOS 14.0, *) {
      GCKeyboard.coalesced?.keyboardInput?.keyChangedHandler = nil
    }
    controllerElementValues.removeAll()
  }

  private func configure(_ controller: GCController) {
    if let gamepad = controller.extendedGamepad {
      prime(gamepad)
      gamepad.valueChangedHandler = { [weak self, weak controller] _, element in
        self?.handleControllerElement(element, controller: controller)
      }
    } else if let gamepad = controller.microGamepad {
      prime(gamepad)
      gamepad.valueChangedHandler = { [weak self, weak controller] _, element in
        self?.handleControllerElement(element, controller: controller)
      }
    } else if let gamepad = controller.gamepad {
      prime(gamepad)
      gamepad.valueChangedHandler = { [weak self, weak controller] _, element in
        self?.handleControllerElement(element, controller: controller)
      }
    }
  }

  private func profile(for controller: GCController) -> GCPhysicalInputProfile? {
    if let profile = controller.extendedGamepad { return profile }
    if let profile = controller.microGamepad { return profile }
    return controller.gamepad
  }

  private func prime(_ profile: GCPhysicalInputProfile) {
    for element in profile.allElements {
      guard let values = values(for: element) else { continue }
      controllerElementValues[ObjectIdentifier(element)] = values
    }
  }

  private func forget(_ controller: GCController) {
    guard let profile = profile(for: controller) else { return }
    for element in profile.allElements {
      controllerElementValues.removeValue(forKey: ObjectIdentifier(element))
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
    if let touchpad = element as? GCControllerTouchpad {
      return [
        Float(touchpad.touchState.rawValue),
        touchpad.button.value,
        touchpad.touchSurface.xAxis.value,
        touchpad.touchSurface.yAxis.value,
      ]
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
      if button.value <= controllerDeadZone {
        controllerElementValues[identifier] = current
        return
      }
      if controllerValueMoved(from: baseline[0], to: button.value) {
        controllerElementValues[identifier] = current
        emit(kind: "gamepad", controller: controller)
      }
      return
    }

    if zip(baseline, current).contains(where: {
      controllerValueMoved(from: $0.0, to: $0.1)
    }) {
      controllerElementValues[identifier] = current
      emit(kind: "gamepad", controller: controller)
    }
  }

  @available(iOS 14.0, *)
  private func configureKeyboard() {
    GCKeyboard.coalesced?.keyboardInput?.keyChangedHandler = {
      [weak self] _, _, _, pressed in
      if pressed { self?.emit(kind: "keyboard") }
    }
  }

  private func updatePointerRecognizers() {
    guard let view = viewController?.view else { return }

    if touchRecognizer == nil {
      let recognizer = UITapGestureRecognizer(
        target: self,
        action: #selector(handleTouch)
      )
      recognizer.cancelsTouchesInView = false
      recognizer.delaysTouchesBegan = false
      recognizer.allowedTouchTypes = [
        NSNumber(value: UITouch.TouchType.direct.rawValue),
      ]
      view.addGestureRecognizer(recognizer)
      touchRecognizer = recognizer
    }
    touchRecognizer?.isEnabled = detectTouch && eventSink != nil

    if #available(iOS 13.4, *), hoverRecognizer == nil {
      let recognizer = UIHoverGestureRecognizer(
        target: self,
        action: #selector(handleHover(_:))
      )
      recognizer.cancelsTouchesInView = false
      view.addGestureRecognizer(recognizer)
      hoverRecognizer = recognizer
    }
    hoverRecognizer?.isEnabled = detectMouse && eventSink != nil
  }

  @objc private func handleTouch() {
    emit(kind: "touch")
  }

  @objc private func handleHover(_ recognizer: UIGestureRecognizer) {
    if recognizer.state == .began || recognizer.state == .changed {
      emit(kind: "mouse")
    }
  }
}
