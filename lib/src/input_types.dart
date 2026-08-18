import 'dart:async';

import 'package:flutter/foundation.dart';

/// The input-device category reported by the native event source.
enum InputDeviceKind { keyboard, mouse, touch, gamepad }

/// A native input event used to update [InputDeviceTracker].
class InputDeviceEvent {
  const InputDeviceEvent({
    this.vendorId,
    this.productId,
    this.kind = InputDeviceKind.gamepad,
  });

  final int? vendorId;
  final int? productId;
  final InputDeviceKind kind;

  factory InputDeviceEvent.fromMap(Map<Object?, Object?> event) {
    final vendorId = event['vendorId'];
    final productId = event['productId'];
    return InputDeviceEvent(
      vendorId: vendorId is num ? vendorId.toInt() : null,
      productId: productId is num ? productId.toInt() : null,
      kind: switch (event['kind']) {
        'keyboard' => InputDeviceKind.keyboard,
        'mouse' => InputDeviceKind.mouse,
        'touch' => InputDeviceKind.touch,
        'gamepad' => InputDeviceKind.gamepad,
        _ when vendorId == null => InputDeviceKind.keyboard,
        _ => InputDeviceKind.gamepad,
      },
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'vendorId': vendorId,
    'productId': productId,
    'kind': kind.name,
  };
}

/// Converts native USB vendor/product IDs to an asset folder name.
String deviceFromHardwareIds(
  int? vendorId,
  int? productId, {
  /// Native category of the device that produced the input.
  InputDeviceKind inputKind = InputDeviceKind.gamepad,

  /// Additional exact VID/PID mappings. These override built-in mappings.
  Map<int, Map<int, String>> additionalDevicesMap = const {},
}) {
  switch (inputKind) {
    case InputDeviceKind.mouse:
    case InputDeviceKind.touch:
    case InputDeviceKind.keyboard:
      return 'Keyboard';
    case InputDeviceKind.gamepad:
      break;
  }

  final customDevice = vendorId == null || productId == null
      ? null
      : additionalDevicesMap[vendorId]?[productId];
  if (customDevice != null) return customDevice;

  if (vendorId == null) return 'Keyboard';

  switch (vendorId) {
    case 1118: // Microsoft
      return switch (productId) {
        2834 || 2835 => 'Xbox Series X-S',
        654 || 655 || 657 || 681 || 1817 => 'Xbox 360',
        _ => 'Xbox One',
        // 721 (0x02D1) — Xbox One controller
        // 733 (0x02DD) — Xbox One controller, 2015 firmware
        // 739 (0x02E3) — Xbox One Elite controller
        // 746 (0x02EA) — Xbox One S controller
        // 2816 (0x0B00) — Xbox Elite Series 2
      };
    case 1356: // Sony
      return switch (productId) {
        3302 || 3570 => 'PS5',
        616 => 'PS3',
        _ => 'PS4', // PS4 ids, if ever needed: 1476 || 2508 || 2976
      };
    case 1406: // Nintendo
      return switch (productId) {
        774 => 'Wii',
        8198 || 8199 || 8206 => 'Switch Joy-Con',
        _ => 'Switch Pro', // 8201
      };
    case 10462: // Valve
      return switch (productId) {
        4354 || 4418 => 'Steam (G1)',
        _ => 'Steam (G2)',
      // Steam G2 ids, if ever needed: 4866 || 4867 || 4868 || 4869
      // Steamdeck PID is 4613
      };
    case 5426: // Razer
      return switch (productId) {
        4103 || 4106 || 4107 || 4108 || 4100
        || 4105 || 4352  => 'PS4',
        _ => 'Xbox One',
      };
    case 12933: // Nacon
      return switch (productId) {
        1634 || 3352 || 3353 || 1553 || 3344 || 3336 => 'PS4',
        _ => 'Xbox One',
      };
    case 3853: // Hori
      return switch (productId) {
        94 || 102 || 238 => 'PS4',
        193 || 146 => 'Switch Pro',
        _ => 'Xbox One',
      };
    case 11720: // 8bitdo
      return switch (productId) {
        24579 || 24585 || 24577 || 24578 || 10345
        || 10346 => 'Switch Pro',
        _ => 'Xbox One',
      };
    case 53769: // Ultimarc // PIDs: 769, 1056, 1040
    case 16: // Akishop // PIDs: 130
    case 3090: // Brook // PIDs: 3120
      return 'Arcade';
    default:
      return 'Xbox One';
  }
}

/// Mutable last-input hardware folder name shared by prompts.
class InputDeviceTracker extends ValueNotifier<String> {
  InputDeviceTracker({
    String initial = 'Keyboard',

    this._additionalDevicesMap = const {},
    this.detectMouse = false,
    this.detectTouch = false,
  }) : super(initial);

  final Map<int, Map<int, String>> _additionalDevicesMap;

  /// Whether native mouse input should enter the hardware-ID event stream.
  final bool detectMouse;

  /// Whether native touch input should enter the hardware-ID event stream.
  final bool detectTouch;

  StreamSubscription<InputDeviceEvent>? _inputSubscription;

  int? vendorId;
  int? productId;
  InputDeviceKind? inputKind;

  void updateDevice(String device) {
    vendorId = null;
    productId = null;
    inputKind = null;
    _updateValue(device);
  }

  void updateHardwareIds(
    int? vendorId,
    int? productId, {
    InputDeviceKind? inputKind,
  }) {
    this.vendorId = vendorId;
    this.productId = productId;
    this.inputKind = inputKind ??
        (vendorId == null
            ? InputDeviceKind.keyboard
            : InputDeviceKind.gamepad);
    _updateValue(deviceFromHardwareIds(
      vendorId,
      productId,
      inputKind: this.inputKind!,
      additionalDevicesMap: _additionalDevicesMap,
    ));
  }

  void _updateValue(String device) {
    if (value == device) {
      notifyListeners();
    } else {
      value = device;
    }
  }

  void bind(Stream<InputDeviceEvent> events) {
    unbind();
    _inputSubscription = events.listen(
      (event) => updateHardwareIds(
        event.vendorId,
        event.productId,
        inputKind: event.kind,
      ),
    );
  }

  void unbind() {
    final subscription = _inputSubscription;
    _inputSubscription = null;
    subscription?.cancel();
  }

  @override
  void dispose() {
    unbind();
    super.dispose();
  }
}
