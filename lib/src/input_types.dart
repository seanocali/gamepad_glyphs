import 'package:flutter/foundation.dart';

/// Semantic inputs that can be used by an [InputPrompt].
enum GamepadInputType {
  a,
  b,
  x,
  y,
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

/// The controller families currently represented by the bundled glyphs.
enum InputDeviceModel {
  keyboard,
  xbox360,
  xboxOne,
  xboxSeriesXs,
  ps3,
  ps4,
  ps5,
  wii,
  switchPro,
  steam,
}

/// Identifies the device whose input was most recently observed.
class InputDeviceProfile {
  const InputDeviceProfile(this.model);

  const InputDeviceProfile.keyboard() : this(InputDeviceModel.keyboard);

  final InputDeviceModel model;

  bool get isKeyboard => model == InputDeviceModel.keyboard;

  /// Converts the USB vendor/product IDs used by the original control.
  ///
  /// Unknown devices intentionally fall back to the keyboard profile, which
  /// matches the original control's safe fallback behavior.
  factory InputDeviceProfile.fromHardwareIds(int? vendorId, int? productId) {
    if (vendorId == null) return const InputDeviceProfile.keyboard();

    switch (vendorId) {
      case 1118: // Microsoft
        switch (productId) {
          case 702:
            return const InputDeviceProfile(InputDeviceModel.xbox360);
          case 721:
          case 733:
          case 746:
            return const InputDeviceProfile(InputDeviceModel.xboxOne);
          default:
            return const InputDeviceProfile(InputDeviceModel.xboxOne);
        }
      case 1356: // Sony
        switch (productId) {
          case 3302:
            return const InputDeviceProfile(InputDeviceModel.ps5);
          case 1476:
          case 2976:
          case 6604:
            return const InputDeviceProfile(InputDeviceModel.ps4);
          default:
            return const InputDeviceProfile(InputDeviceModel.ps4);
        }
      case 1406: // Nintendo
        switch (productId) {
          case 774:
            return const InputDeviceProfile(InputDeviceModel.wii);
          default:
            return const InputDeviceProfile(InputDeviceModel.switchPro);
        }
      case 10462: // Valve
        return const InputDeviceProfile(InputDeviceModel.steam);
      default:
        return const InputDeviceProfile.keyboard();
    }
  }

  String get assetPrefix {
    switch (model) {
      case InputDeviceModel.keyboard:
        return 'Keyboard';
      case InputDeviceModel.xbox360:
        return 'Microsoft/Xbox 360';
      case InputDeviceModel.xboxOne:
        return 'Microsoft/Xbox One';
      case InputDeviceModel.xboxSeriesXs:
        return 'Microsoft/Xbox Series XS';
      case InputDeviceModel.ps3:
        return 'Sony/PS3';
      case InputDeviceModel.ps4:
        return 'Sony/PS4';
      case InputDeviceModel.ps5:
        return 'Sony/PS5';
      case InputDeviceModel.wii:
        return 'Nintendo/Wii';
      case InputDeviceModel.switchPro:
        return 'Nintendo/Switch';
      case InputDeviceModel.steam:
        return 'Valve/Steam';
    }
  }

  @override
  bool operator ==(Object other) =>
      other is InputDeviceProfile && other.model == model;

  @override
  int get hashCode => model.hashCode;
}

/// Mutable last-input state that can be shared by multiple prompts.
class InputDeviceTracker extends ValueNotifier<InputDeviceProfile> {
  InputDeviceTracker({
    InputDeviceProfile initial = const InputDeviceProfile.keyboard(),
  }) : super(initial);

  void updateDevice(InputDeviceProfile device) {
    value = device;
  }

  void updateHardwareIds(int? vendorId, int? productId) {
    updateDevice(InputDeviceProfile.fromHardwareIds(vendorId, productId));
  }
}
