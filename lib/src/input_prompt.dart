import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'input_glyph_table.dart';
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
    this.glyphs = defaultInputGlyphs,
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

  /// The mapping used to resolve semantic inputs to asset names.
  final InputGlyphTable glyphs;
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
    InputGlyphTable glyphs = defaultInputGlyphs,
    bool useMonochrome = false,
    bool reverseAxes = false,
    String? mappedKeyboardKey,
  }) {
    if (input == GamepadInputType.none) return '';

    final key = reverseAxes ? _reverseAxis(input) : input;

    final monochromeFamily = _monochromeFamily(device.model);
    if (useMonochrome && monochromeFamily != null) {
      return 'assets/input_prompt/Monochrome/$monochromeFamily/${glyphs.monochromeIndex(key)}.svg';
    }

    final keyName = device.isKeyboard && mappedKeyboardKey != null
        ? mappedKeyboardKey
        : glyphs.glyphName(key, device.model);
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
    var prefix = device.assetPrefix.substring(
      device.assetPrefix.indexOf('/') + 1,
    );
    // The bundled Series XS collection has one legacy trigger asset under
    // the shorter "Xbox Series X" prefix.
    if (device.model == InputDeviceModel.xboxSeriesXs &&
        keyName == 'LeftTrigger') {
      prefix = 'Xbox Series X';
    }
    return 'assets/input_prompt/$folder/$prefix-$keyName.svg';
  }

  static String? _monochromeFamily(InputDeviceModel model) {
    switch (model) {
      case InputDeviceModel.xbox360:
      case InputDeviceModel.xboxOne:
      case InputDeviceModel.xboxSeriesXs:
        return 'Xbox';
      case InputDeviceModel.ps3:
      case InputDeviceModel.ps4:
      case InputDeviceModel.ps5:
        return 'PlayStation';
      default:
        return null;
    }
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
      glyphs: glyphs,
    );
    if (path.isEmpty) return SizedBox(width: width, height: height);

    return SvgPicture.asset(
      path,
      package: 'gamepad_glyphs',
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      colorFilter:
          useMonochrome && _monochromeFamily(currentDevice.model) != null
          ? ColorFilter.mode(
              theme == InputPromptTheme.dark ? Colors.white : Colors.black,
              BlendMode.srcIn,
            )
          : null,
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
}
