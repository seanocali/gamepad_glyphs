import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'input_types.dart';

/// The visual treatment used for keyboard glyphs.
enum InputPromptTheme { light, dark }

/// Displays the glyph for a semantic input on the last-used device.
class InputPrompt extends StatelessWidget {
  const InputPrompt({
    super.key,
    required this.input,
    this.device,
    this.deviceListenable,
    this.theme = InputPromptTheme.light,
    this.useMonochrome = false,
    this.reverseAxes = false,
    this.mappedKeyboardKey,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  }) : assert(device == null || deviceListenable == null);

  final GamepadInputType input;

  /// A fixed device profile for prompts that do not need to listen for input.
  final InputDeviceProfile? device;

  /// A shared last-input state, normally an [InputDeviceTracker].
  final ValueListenable<InputDeviceProfile>? deviceListenable;

  final InputPromptTheme theme;
  final bool useMonochrome;
  final bool reverseAxes;
  final String? mappedKeyboardKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  /// Returns the package asset used for a prompt configuration.
  static String assetPathFor({
    required GamepadInputType input,
    required InputDeviceProfile device,
    InputPromptTheme theme = InputPromptTheme.light,
    bool useMonochrome = false,
    bool reverseAxes = false,
    String? mappedKeyboardKey,
  }) {
    if (input == GamepadInputType.none) return '';

    final key = reverseAxes ? _reverseAxis(input) : input;
    final keyName = device.isKeyboard
        ? (mappedKeyboardKey ?? _keyboardKeyName(key))
        : _gamepadKeyName(key, device.model);
    if (keyName == null) return '';

    if (device.isKeyboard) {
      final themeFolder = useMonochrome
          ? 'Monochrome${theme == InputPromptTheme.dark ? 'Dark' : 'Light'}'
          : theme == InputPromptTheme.dark
          ? 'Dark'
          : 'Light';
      return 'assets/input_prompt/Keyboard/$themeFolder/$keyName.svg';
    }

    final folder = device.assetPrefix.split('/').first;
    final prefix = device.assetPrefix.substring(
      device.assetPrefix.indexOf('/') + 1,
    );
    return 'assets/input_prompt/$folder/$prefix-$keyName.svg';
  }

  @override
  Widget build(BuildContext context) {
    final listenable = deviceListenable;
    if (listenable == null) {
      return _buildGlyph(device ?? const InputDeviceProfile.keyboard());
    }

    return ValueListenableBuilder<InputDeviceProfile>(
      valueListenable: listenable,
      builder: (context, currentDevice, child) => _buildGlyph(currentDevice),
    );
  }

  Widget _buildGlyph(InputDeviceProfile currentDevice) {
    final path = assetPathFor(
      input: input,
      device: currentDevice,
      theme: theme,
      useMonochrome: useMonochrome,
      reverseAxes: reverseAxes,
      mappedKeyboardKey: mappedKeyboardKey,
    );
    if (path.isEmpty) return SizedBox(width: width, height: height);

    return SvgPicture.asset(
      path,
      package: 'gamepad_glyphs',
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      semanticsLabel: '${currentDevice.model.name} ${input.name} input',
    );
  }

  static GamepadInputType _reverseAxis(GamepadInputType input) {
    switch (input) {
      case GamepadInputType.dPadUpDown:
        return GamepadInputType.dPadLeftRight;
      case GamepadInputType.dPadLeftRight:
        return GamepadInputType.dPadUpDown;
      case GamepadInputType.leftThumbstickLeftRight:
        return GamepadInputType.leftThumbstickUpDown;
      case GamepadInputType.leftThumbstickUpDown:
        return GamepadInputType.leftThumbstickLeftRight;
      case GamepadInputType.rightThumbstickLeftRight:
        return GamepadInputType.rightThumbstickUpDown;
      case GamepadInputType.rightThumbstickUpDown:
        return GamepadInputType.rightThumbstickLeftRight;
      default:
        return input;
    }
  }

  static String? _gamepadKeyName(
    GamepadInputType input,
    InputDeviceModel model,
  ) {
    switch (model) {
      case InputDeviceModel.ps3:
        return _playStationKeyName(input, ps5: false, ps4: false);
      case InputDeviceModel.ps4:
        return _playStationKeyName(input, ps5: false, ps4: true);
      case InputDeviceModel.ps5:
        return _playStationKeyName(input, ps5: true, ps4: true);
      case InputDeviceModel.switchPro:
        switch (input) {
          case GamepadInputType.leftShoulder:
            return 'L';
          case GamepadInputType.rightShoulder:
            return 'R';
          case GamepadInputType.leftRightShoulder:
            return 'LR';
          case GamepadInputType.leftTrigger:
            return 'ZL';
          case GamepadInputType.rightTrigger:
            return 'ZR';
          case GamepadInputType.leftRightTrigger:
            return 'ZLZR';
          default:
            return _enumAssetName(input);
        }
      case InputDeviceModel.xbox360:
        switch (input) {
          case GamepadInputType.view:
            return 'Back';
          case GamepadInputType.menu:
            return 'Start';
          default:
            return _enumAssetName(input);
        }
      case InputDeviceModel.keyboard:
        return _keyboardKeyName(input);
      default:
        return _enumAssetName(input);
    }
  }

  static String _playStationKeyName(
    GamepadInputType input, {
    required bool ps4,
    required bool ps5,
  }) {
    switch (input) {
      case GamepadInputType.a:
        return 'Cross';
      case GamepadInputType.b:
        return 'Circle';
      case GamepadInputType.x:
        return 'Square';
      case GamepadInputType.y:
        return 'Triangle';
      case GamepadInputType.leftShoulder:
        return 'L1';
      case GamepadInputType.rightShoulder:
        return 'R1';
      case GamepadInputType.leftTrigger:
        return 'L2';
      case GamepadInputType.rightTrigger:
        return 'R2';
      case GamepadInputType.leftThumbstickButton:
        return 'L3';
      case GamepadInputType.rightThumbstickButton:
        return 'R3';
      case GamepadInputType.leftRightShoulder:
        return 'L1R1';
      case GamepadInputType.leftRightTrigger:
        return 'L2R2';
      case GamepadInputType.view:
        return ps5
            ? 'Create'
            : ps4
            ? 'Share'
            : 'Select';
      case GamepadInputType.menu:
        return ps4 || ps5 ? 'Options' : 'Start';
      default:
        return _enumAssetName(input);
    }
  }

  static String? _keyboardKeyName(GamepadInputType input) {
    const names = <GamepadInputType, String>{
      GamepadInputType.a: 'Enter',
      GamepadInputType.b: 'Back',
      GamepadInputType.x: 'Space',
      GamepadInputType.y: '~',
      GamepadInputType.view: 'Home',
      GamepadInputType.menu: 'Escape',
      GamepadInputType.leftShoulder: 'ChevronLeft',
      GamepadInputType.rightShoulder: 'ChevronRight',
      GamepadInputType.leftRightShoulder: 'ChevronLeftRight',
      GamepadInputType.leftTrigger: 'BracketLeft',
      GamepadInputType.rightTrigger: 'BracketRight',
      GamepadInputType.leftRightTrigger: 'BracketLeftRight',
      GamepadInputType.dPad: 'UpDownLeftRight',
      GamepadInputType.dPadUp: 'Up',
      GamepadInputType.dPadDown: 'Down',
      GamepadInputType.dPadLeft: 'Left',
      GamepadInputType.dPadRight: 'Right',
      GamepadInputType.dPadUpLeft: 'UpLeft',
      GamepadInputType.dPadDownRight: 'DownRight',
      GamepadInputType.dPadDownLeft: 'DownLeft',
      GamepadInputType.dPadUpRight: 'UpRight',
      GamepadInputType.dPadUpDown: 'UpDown',
      GamepadInputType.dPadLeftRight: 'LeftRight',
      GamepadInputType.leftThumbstick: 'WSAD',
      GamepadInputType.leftThumbstickClockwise: 'R',
      GamepadInputType.leftThumbstickCounterclockwise: 'Q',
      GamepadInputType.leftThumbstickUp: 'W',
      GamepadInputType.leftThumbstickDown: 'S',
      GamepadInputType.leftThumbstickLeft: 'A',
      GamepadInputType.leftThumbstickRight: 'D',
      GamepadInputType.leftThumbstickUpLeft: 'WS',
      GamepadInputType.leftThumbstickDownRight: 'SD',
      GamepadInputType.leftThumbstickDownLeft: 'SA',
      GamepadInputType.leftThumbstickUpRight: 'WD',
      GamepadInputType.leftThumbstickUpDown: 'WS',
      GamepadInputType.leftThumbstickLeftRight: 'AD',
      GamepadInputType.leftThumbstickButton: 'ChevronLeft',
      GamepadInputType.rightThumbstick: '8246',
      GamepadInputType.rightThumbstickClockwise: '9',
      GamepadInputType.rightThumbstickCounterclockwise: '7',
      GamepadInputType.rightThumbstickUp: '8',
      GamepadInputType.rightThumbstickDown: '2',
      GamepadInputType.rightThumbstickLeft: '4',
      GamepadInputType.rightThumbstickRight: '6',
      GamepadInputType.rightThumbstickUpLeft: '84',
      GamepadInputType.rightThumbstickDownRight: '26',
      GamepadInputType.rightThumbstickDownLeft: '24',
      GamepadInputType.rightThumbstickUpRight: '86',
      GamepadInputType.rightThumbstickUpDown: '82',
      GamepadInputType.rightThumbstickLeftRight: '46',
      GamepadInputType.rightThumbstickButton: 'ChevronRight',
      GamepadInputType.homeButton: 'End',
    };
    return names[input];
  }

  static String _enumAssetName(GamepadInputType input) {
    return input.name[0].toUpperCase() + input.name.substring(1);
  }
}
