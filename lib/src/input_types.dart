import 'dart:async';

import 'package:flutter/foundation.dart';

/// A native input event used to update [InputDeviceTracker].
class InputDeviceEvent {
  const InputDeviceEvent({this.vendorId, this.productId});

  final int? vendorId;
  final int? productId;

  InputDeviceProfile get profile =>
      InputDeviceProfile.fromHardwareIds(vendorId, productId);

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
/// Semantic inputs that can be used by a [GamepadGlyph].
enum GamepadInputType {
  north,
  south,
  east,
  west,
  view,
  menu,
  leftShoulder,
  rightShoulder,
  leftRightShoulder,
  leftTrigger,
  rightTrigger,
  leftRightTrigger,
  dPad,
  dPadUp,
  dPadDown,
  dPadLeft,
  dPadRight,
  dPadUpLeft,
  dPadDownRight,
  dPadDownLeft,
  dPadUpRight,
  leftThumbstick,
  leftThumbstickClockwise,
  leftThumbstickCounterclockwise,
  leftThumbstickUp,
  leftThumbstickDown,
  leftThumbstickLeft,
  leftThumbstickRight,
  leftThumbstickUpLeft,
  leftThumbstickDownRight,
  leftThumbstickDownLeft,
  leftThumbstickUpRight,
  leftThumbstickLeftRight,
  leftThumbstickUpDown,
  leftThumbstickButton,
  rightThumbstick,
  rightThumbstickClockwise,
  rightThumbstickCounterclockwise,
  rightThumbstickUp,
  rightThumbstickDown,
  rightThumbstickLeft,
  rightThumbstickRight,
  rightThumbstickUpLeft,
  rightThumbstickDownRight,
  rightThumbstickDownLeft,
  rightThumbstickUpRight,
  rightThumbstickLeftRight,
  rightThumbstickUpDown,
  rightThumbstickButton,
  homeButton,
  dPadUpDown,
  dPadLeftRight,
  none,
}

/// Selects whether a [GamepadGlyph] follows input or always uses one family.
enum GamepadDevice {
  keyboard,
  xbox360,
  xboxOne,
  xboxSeriesXs,
  ps3,
  ps4,
  ps5,
  wii,
  switchJoyCon,
  steamG1,
}

/// Identifies the device whose input was most recently observed.
class InputDeviceProfile {
  const InputDeviceProfile(this.type, {this.isRecognized = true});

  const InputDeviceProfile.keyboard() : this(GamepadDevice.keyboard);

  final GamepadDevice type;
  final bool isRecognized;

  bool get isKeyboard => type == GamepadDevice.keyboard;

  /// Converts the USB vendor/product IDs used by the original control.
  ///
  /// Unknown non-keyboard devices are marked unrecognized so a glyph can use
  /// its configured default device family.
  factory InputDeviceProfile.fromHardwareIds(int? vendorId, int? productId) {
    if (vendorId == null) return const InputDeviceProfile.keyboard();

    switch (vendorId) {
      case 1118: // Microsoft
        switch (productId) {
          case 702:
            return const InputDeviceProfile(GamepadDevice.xbox360);
          case 721:
          case 733:
          case 746:
            return const InputDeviceProfile(GamepadDevice.xboxOne);
          default:
            return const InputDeviceProfile(GamepadDevice.xboxOne);
        }
      case 1356: // Sony
        switch (productId) {
          case 3302:
            return const InputDeviceProfile(GamepadDevice.ps5);
          case 1476:
          case 2976:
          case 6604:
            return const InputDeviceProfile(GamepadDevice.ps4);
          default:
            return const InputDeviceProfile(GamepadDevice.ps4);
        }
      case 1406: // Nintendo
        switch (productId) {
          case 774:
            return const InputDeviceProfile(GamepadDevice.wii);
          default:
            return const InputDeviceProfile(GamepadDevice.switchJoyCon);
        }
      case 10462: // Valve
        return const InputDeviceProfile(GamepadDevice.steamG1);
      default:
        return const InputDeviceProfile(
          GamepadDevice.xboxOne,
          isRecognized: false,
        );
    }
  }

  String get assetPrefix {
    switch (type) {
      case GamepadDevice.keyboard:
        return 'Keyboard';
      case GamepadDevice.xbox360:
        return 'Microsoft/Xbox 360';
      case GamepadDevice.xboxOne:
        return 'Microsoft/Xbox One';
      case GamepadDevice.xboxSeriesXs:
        return 'Microsoft/Xbox Series XS';
      case GamepadDevice.ps3:
        return 'Sony/PS3';
      case GamepadDevice.ps4:
        return 'Sony/PS4';
      case GamepadDevice.ps5:
        return 'Sony/PS5';
      case GamepadDevice.wii:
        return 'Nintendo/Wii';
      case GamepadDevice.switchJoyCon:
        return 'Nintendo/Switch';
      case GamepadDevice.steamG1:
        return 'Valve/Steam-G1';
    }
  }

  @override
  bool operator ==(Object other) =>
      other is InputDeviceProfile &&
      other.type == type &&
      other.isRecognized == isRecognized;

  @override
  int get hashCode => Object.hash(type, isRecognized);
}

/// Mutable last-input state that can be shared by multiple prompts.
class InputDeviceTracker extends ValueNotifier<InputDeviceProfile> {
  InputDeviceTracker({
    InputDeviceProfile initial = const InputDeviceProfile.keyboard(),
  }) : super(initial);

  StreamSubscription<InputDeviceEvent>? _inputSubscription;

  int? vendorId;
  int? productId;

  void updateDevice(InputDeviceProfile device) {
    vendorId = null;
    productId = null;
    value = device;
  }

  void updateHardwareIds(int? vendorId, int? productId) {
    this.vendorId = vendorId;
    this.productId = productId;
    value = InputDeviceProfile.fromHardwareIds(vendorId, productId);
  }

  /// Binds this tracker to native input events, replacing any prior binding.
  void bind(Stream<InputDeviceEvent> events) {
    unbind();
    _inputSubscription = events.listen(
      (event) => updateHardwareIds(event.vendorId, event.productId),
    );
  }

  /// Stops listening to native input events.
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
