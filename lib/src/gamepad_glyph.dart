import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'input_glyph_table.dart';
import 'input_types.dart';
import '../gamepad_glyphs_platform_interface.dart';

/// Displays the glyph for a semantic input on the last-used device.
class GamepadGlyph extends StatefulWidget {
  GamepadGlyph({
    super.key,
    required this.input,
    this.forceDeviceType,
    this.defaultDeviceType = GamepadDevice.xboxOne,
    this.device,
    this.deviceListenable,
    this.style = 'default',
    this.deviceStyles = const <GamepadDevice, String>{},
    this.assetRoot = 'assets/input_prompt',
    this.assetPackage = 'gamepad_glyphs',
    InputGlyphTable? glyphs,
    this.reverseAxes = false,
    this.mappedKeyboardKey,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  }) : glyphs = glyphs ?? defaultInputGlyphs,
       assert(device == null || deviceListenable == null);

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

  /// The preferred style subfolder for all hardware.
  ///
  /// The string is matched directly against a style folder beneath the active
  /// hardware folder. If the style or glyph is absent, the `default` style is
  /// tried instead without reporting an error.
  final String style;

  /// Per-hardware style overrides. Values are style subfolder names, such as
  /// `MonochromeDark`. They take precedence over [style].
  final Map<GamepadDevice, String> deviceStyles;

  /// Root directory containing hardware/style asset folders.
  final String assetRoot;

  /// Package containing the assets. Set to null for application assets.
  final String? assetPackage;

  /// The mapping used to resolve semantic inputs to asset names.
  final InputGlyphTable glyphs;
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
    String style = 'default',
    InputGlyphTable? glyphs,
    String assetRoot = 'assets/input_prompt',
    bool reverseAxes = false,
    String? mappedKeyboardKey,
  }) {
    final paths = assetPathsFor(
      input: input,
      device: device,
      style: style,
      glyphs: glyphs,
      assetRoot: assetRoot,
      reverseAxes: reverseAxes,
      mappedKeyboardKey: mappedKeyboardKey,
    );
    return paths.isEmpty ? '' : paths.first;
  }

  /// Returns the requested style path followed by the silent `default`
  /// fallback path when needed.
  static List<String> assetPathsFor({
    required GamepadInputType input,
    required InputDeviceProfile device,
    String style = 'default',
    InputGlyphTable? glyphs,
    String assetRoot = 'assets/input_prompt',
    bool reverseAxes = false,
    String? mappedKeyboardKey,
  }) {
    if (input == GamepadInputType.none) return const <String>[];

    final glyphTable = glyphs ?? defaultInputGlyphs;
    final key = reverseAxes ? _reverseAxis(input) : input;
    final keyName = device.isKeyboard && mappedKeyboardKey != null
        ? mappedKeyboardKey
        : glyphTable.glyphName(key, device.type);
    if (keyName == null) return const <String>[];

    final requestedStyle = style == 'default'
        ? glyphTable.styleFor(device.type)
        : style;
    final requestedPath = _assetPathForStyle(
      device: device,
      style: requestedStyle,
      assetRoot: assetRoot,
      keyName: keyName,
    );
    if (requestedStyle == 'default') return <String>[requestedPath];

    return <String>[
      requestedPath,
      _assetPathForStyle(
        device: device,
        style: 'default',
        assetRoot: assetRoot,
        keyName: keyName,
      ),
    ];
  }

  static String _assetPathForStyle({
    required InputDeviceProfile device,
    required String style,
    required String assetRoot,
    required String keyName,
  }) {
    return '$assetRoot/${device.type.assetFolder}/$style/$keyName';
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
    final paths = GamepadGlyph.assetPathsFor(
      input: widget.input,
      device: currentDevice,
      style: widget.deviceStyles[currentDevice.type] ?? widget.style,
      assetRoot: widget.assetRoot,
      reverseAxes: widget.reverseAxes,
      mappedKeyboardKey: widget.mappedKeyboardKey,
      glyphs: widget.glyphs,
    );
    if (paths.isEmpty) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    return FutureBuilder<Uint8List?>(
      future: _loadFirstAsset(paths, widget.assetPackage),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return SizedBox(width: widget.width, height: widget.height);
        }

        final path = paths.first;
        if (path.toLowerCase().endsWith('.svg')) {
          return SvgPicture.memory(
            bytes,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            alignment: widget.alignment,
            errorBuilder: (context, error, stackTrace) =>
                SizedBox(width: widget.width, height: widget.height),
            semanticsLabel:
                '${currentDevice.type.name} ${widget.input.name} input',
          );
        }
        return Image.memory(
          bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          errorBuilder: (context, error, stackTrace) =>
              SizedBox(width: widget.width, height: widget.height),
          semanticLabel:
              '${currentDevice.type.name} ${widget.input.name} input',
        );
      },
    );
  }

  static Future<Uint8List?> _loadFirstAsset(
    Iterable<String> paths,
    String? assetPackage,
  ) async {
    for (final path in paths) {
      try {
        final assetPath = assetPackage == null
            ? path
            : 'packages/$assetPackage/$path';
        final data = await rootBundle.load(assetPath);
        return data.buffer.asUint8List();
      } catch (_) {
        // A style may not exist for this hardware. Try its default style next.
      }
    }
    return null;
  }
}
