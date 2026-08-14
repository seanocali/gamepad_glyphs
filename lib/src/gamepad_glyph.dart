import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'input_glyph_table.dart';
import 'input_types.dart';
import '../gamepad_glyphs_platform_interface.dart';

/// The visual treatment used for keyboard glyphs.
enum GamepadGlyphTheme { light, dark }

/// Displays the glyph for a semantic input on the last-used device.
class GamepadGlyph extends StatefulWidget {
  const GamepadGlyph({
    super.key,
    required this.input,
    this.forceDeviceType,
    this.defaultDeviceType = GamepadDevice.xboxOne,
    this.device,
    this.deviceListenable,
    this.theme = GamepadGlyphTheme.light,
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

  /// Forces a fixed device family and disables automatic input tracking.
  final GamepadDevice? forceDeviceType;

  /// Device family used when automatic input comes from an unrecognized
  /// controller. It also supplies the initial automatic display.
  final GamepadDevice defaultDeviceType;

  /// A fixed device profile for prompts that do not need to listen for input.
  final InputDeviceProfile? device;

  /// A shared last-input state, normally an [InputDeviceTracker].
  final ValueListenable<InputDeviceProfile>? deviceListenable;

  final GamepadGlyphTheme theme;

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
    GamepadGlyphTheme theme = GamepadGlyphTheme.light,
    InputGlyphTable glyphs = defaultInputGlyphs,
    bool useMonochrome = false,
    bool reverseAxes = false,
    String? mappedKeyboardKey,
  }) {
    if (input == GamepadInputType.none) return '';

    final key = reverseAxes ? _reverseAxis(input) : input;

    final monochromeFamily = _monochromeFamily(device.type);
    if (useMonochrome && monochromeFamily != null) {
      return 'assets/input_prompt/Monochrome/$monochromeFamily/${glyphs.monochromeIndex(key)}.svg';
    }

    final keyName = device.isKeyboard && mappedKeyboardKey != null
        ? mappedKeyboardKey
        : glyphs.glyphName(key, device.type);
    if (keyName == null) return '';

    if (device.isKeyboard) {
      final themeFolder = useMonochrome
          ? 'Monochrome${theme == GamepadGlyphTheme.dark ? 'Dark' : 'Light'}'
          : theme == GamepadGlyphTheme.dark
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
    if (device.type == GamepadDevice.xboxSeriesXs &&
        keyName == 'LeftTrigger') {
      prefix = 'Xbox Series X';
    }
    return 'assets/input_prompt/$folder/$prefix-$keyName.svg';
  }

  static String? _monochromeFamily(GamepadDevice type) {
    switch (type) {
      case GamepadDevice.xbox360:
      case GamepadDevice.xboxOne:
      case GamepadDevice.xboxSeriesXs:
        return 'Xbox';
      case GamepadDevice.ps3:
      case GamepadDevice.ps4:
      case GamepadDevice.ps5:
        return 'PlayStation';
      default:
        return null;
    }
  }

  @override
  State<GamepadGlyph> createState() => _GamepadGlyphState();

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
class _GamepadGlyphState extends State<GamepadGlyph> {
  static final _automaticTracker = InputDeviceTracker(
    initial: InputDeviceProfile(GamepadDevice.xboxOne),
  );
  static StreamSubscription<InputDeviceEvent>? _automaticSubscription;
  static int _automaticUsers = 0;

  bool _usesAutomaticTracking = false;

  @override
  void initState() {
    super.initState();
    _updateAutomaticTracking();
  }

  @override
  void didUpdateWidget(covariant GamepadGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAutomaticTracking();
  }

  @override
  void dispose() {
    _releaseAutomaticTracking();
    super.dispose();
  }

  bool get _shouldUseAutomaticTracking =>
      widget.forceDeviceType == null &&
      widget.device == null &&
      widget.deviceListenable == null;

  void _updateAutomaticTracking() {
    final shouldTrack = _shouldUseAutomaticTracking;
    if (shouldTrack == _usesAutomaticTracking) return;

    if (shouldTrack) {
      _retainAutomaticTracking();
    } else {
      _releaseAutomaticTracking();
    }
    _usesAutomaticTracking = shouldTrack;
  }

  void _retainAutomaticTracking() {
    if (_automaticUsers++ == 0) {
      _automaticSubscription = GamepadGlyphsPlatform.instance.inputEvents
          .listen((event) {
            _automaticTracker.updateHardwareIds(
              event.vendorId,
              event.productId,
            );
          });
    }
  }

  void _releaseAutomaticTracking() {
    if (!_usesAutomaticTracking) return;
    if (--_automaticUsers == 0) {
      _automaticSubscription?.cancel();
      _automaticSubscription = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fixedType = widget.forceDeviceType;
    final fixedDevice = fixedType == null
        ? widget.device
        : InputDeviceProfile(fixedType);
    final listenable = fixedType == null
        ? widget.deviceListenable ??
            (_shouldUseAutomaticTracking ? _automaticTracker : null)
        : null;

    if (listenable == null) {
      return _buildGlyph(fixedDevice ?? const InputDeviceProfile.keyboard());
    }

    return ValueListenableBuilder<InputDeviceProfile>(
      valueListenable: listenable,
      builder: (context, currentDevice, child) => _buildGlyph(
        currentDevice.isRecognized
            ? currentDevice
            : InputDeviceProfile(widget.defaultDeviceType),
      ),
    );
  }

  Widget _buildGlyph(InputDeviceProfile currentDevice) {
    final path = GamepadGlyph.assetPathFor(
      input: widget.input,
      device: currentDevice,
      theme: widget.theme,
      useMonochrome: widget.useMonochrome,
      reverseAxes: widget.reverseAxes,
      mappedKeyboardKey: widget.mappedKeyboardKey,
      glyphs: widget.glyphs,
    );
    if (path.isEmpty) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    return SvgPicture.asset(
      path,
      package: 'gamepad_glyphs',
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      colorFilter:
          widget.useMonochrome &&
              GamepadGlyph._monochromeFamily(currentDevice.type) != null
          ? ColorFilter.mode(
              widget.theme == GamepadGlyphTheme.dark
                  ? Colors.white
                  : Colors.black,
              BlendMode.srcIn,
            )
          : null,
      semanticsLabel: '${currentDevice.type.name} ${widget.input.name} input',
    );
  }
}
