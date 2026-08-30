import 'dart:async';

import 'package:flutter/foundation.dart';

/// The input-device category reported by the native event source.
enum InputDeviceKind { keyboard, mouse, touch, remote, gamepad }

/// A native input event used to update [InputDeviceTracker].
class InputDeviceEvent {
  const InputDeviceEvent({
    this.vendorId,
    this.productId,
    this.productCategory,
    this.kind = InputDeviceKind.gamepad,
  });

  final int? vendorId;
  final int? productId;
  final String? productCategory;
  final InputDeviceKind kind;

  factory InputDeviceEvent.fromMap(Map<Object?, Object?> event) {
    final vendorId = event['vendorId'];
    final productId = event['productId'];
    final rawKinds = event['kinds'];
    final kinds = <String>{
      if (rawKinds is Iterable) ...rawKinds.whereType<String>(),
      if (rawKinds is! Iterable && event['kind'] is String)
        event['kind'] as String,
    };

    return InputDeviceEvent(
      vendorId: vendorId is num ? vendorId.toInt() : null,
      productId: productId is num ? productId.toInt() : null,
      productCategory: event['productCategory'] as String?,
      kind: switch (kinds) {
        _ when kinds.contains('gamepad') => InputDeviceKind.gamepad,
        _ when kinds.contains('remote') => InputDeviceKind.remote,
        _ when kinds.contains('keyboard') => InputDeviceKind.keyboard,
        _ when kinds.contains('mouse') => InputDeviceKind.mouse,
        _ when kinds.contains('touch') => InputDeviceKind.touch,
        _ when vendorId == null => InputDeviceKind.keyboard,
        _ => InputDeviceKind.gamepad,
      },
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'vendorId': vendorId,
    'productId': productId,
    'productCategory': productCategory,
    'kind': kind.name,
  };
}

/// Converts Apple's Game Controller product category to an asset folder name.
String deviceFromProductCategory(String productCategory) {
  return switch (productCategory) {
    'GCProductCategorySiriRemote1stGen' ||
    'GCProductCategorySiriRemote2ndGen' => 'Apple TV',
    'GCProductCategoryDualShock4' => 'PS4',
    'GCProductCategoryDualSense' => 'PS5',
    'GCProductCategoryXboxOne' => 'Xbox One',
    'GCProductCategoryXboxSeriesX' => 'Xbox Series X-S',
    'GCProductCategoryMFi' => 'Xbox One',
    _ => '',
  };
}

/// Converts native USB vendor/product IDs to an asset folder name.
String deviceFromHardwareIds(
  int? vendorId,
  int? productId, {
  required InputDeviceKind inputKind,
}) {
  switch (inputKind) {
    case InputDeviceKind.mouse:
      return 'Mouse';
    case InputDeviceKind.touch:
      return 'Touch';
    case InputDeviceKind.keyboard:
      return 'Keyboard';
    case InputDeviceKind.remote:
      if (vendorId == 6353 && productId != null) return 'Google TV';
      if (vendorId == 7439) return 'Fire TV';
      return 'TV Remote';
    case InputDeviceKind.gamepad:
      break;
  }

  // Some platforms can identify controller activity without exposing USB
  // hardware IDs. Use the generic controller artwork in that case.
  if (vendorId == null) return 'Xbox One';

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
        4103 || 4106 || 4107 || 4108 || 4100 || 4105 || 4352 => 'PS4',
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
    case 11720: // 8BitDo
      return switch (productId) {
        24577 || 24578 => 'SNES',
        24579 || 24585 || 10345 || 10346 => 'Switch Pro',
        _ => 'Xbox One',
      };
    case 7439: // Amazon
      return switch (productId) {
        369 || 6473 => 'Luna',
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
    this.detectMouse = false,
    this.detectTouch = false,
  }) : super(initial);

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
    String? productCategory,
  }) {
    this.vendorId = vendorId;
    this.productId = productId;
    this.inputKind =
        inputKind ??
        (vendorId == null ? InputDeviceKind.keyboard : InputDeviceKind.gamepad);

    if (productCategory != null) {
      _updateValue(deviceFromProductCategory(productCategory));
      return;
    }

    _updateValue(
      deviceFromHardwareIds(vendorId, productId, inputKind: this.inputKind!),
    );
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
        productCategory: event.productCategory,
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
