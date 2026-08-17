import 'dart:async';

import 'package:flutter/foundation.dart';

/// A native input event used to update [InputDeviceTracker].
class InputDeviceEvent {
  const InputDeviceEvent({this.vendorId, this.productId});

  final int? vendorId;
  final int? productId;

  String get device => deviceFromHardwareIds(vendorId, productId);

  factory InputDeviceEvent.fromMap(Map<Object?, Object?> event) {
    final vendorId = event['vendorId'];
    final productId = event['productId'];
    return InputDeviceEvent(
      vendorId: vendorId is num ? vendorId.toInt() : null,
      productId: productId is num ? productId.toInt() : null,
    );
  }

  Map<String, int?> toMap() => <String, int?>{
    'vendorId': vendorId,
    'productId': productId,
  };
}

/// Converts native USB vendor/product IDs to an asset folder name.
String deviceFromHardwareIds(int? vendorId, int? productId) {
  if (vendorId == null) return 'Keyboard';

  switch (vendorId) {
    case 1118: // Microsoft
      return switch (productId) {
        2834 || 2835 => 'Xbox Series X-S',
        654 || 655 || 657 ||681 || 1817 => 'Xbox 360',
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
      return productId == 774 ? 'Wii' : 'Switch Joy-Con';
    case 10462: // Valve
      return switch (productId) {
        4354 || 4418 => 'Steam (G1)',
        _ => 'Steam (G2)', // Steam G2 ids, if ever needed: 4866 || 4868
      };
    default:
      return 'Xbox One';
  }
}

/// Mutable last-input hardware folder name shared by prompts.
class InputDeviceTracker extends ValueNotifier<String> {
  InputDeviceTracker({String initial = 'Keyboard'}) : super(initial);

  StreamSubscription<InputDeviceEvent>? _inputSubscription;

  int? vendorId;
  int? productId;

  void updateDevice(String device) {
    vendorId = null;
    productId = null;
    value = device;
  }

  void updateHardwareIds(int? vendorId, int? productId) {
    this.vendorId = vendorId;
    this.productId = productId;
    value = deviceFromHardwareIds(vendorId, productId);
  }

  void bind(Stream<InputDeviceEvent> events) {
    unbind();
    _inputSubscription = events.listen(
      (event) => updateHardwareIds(event.vendorId, event.productId),
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
