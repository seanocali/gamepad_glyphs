import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'input_types.dart';
import '../gamepad_glyphs_platform_interface.dart';

/// Displays the glyph for a semantic input on the last-used device.
class GamepadGlyph extends StatefulWidget {
  static const defaultAssetRoot = 'assets/input_prompt';

  const GamepadGlyph({
    super.key,
    required this.input,
    this.forceDeviceType,
    this.defaultDeviceType = 'Xbox One',
    this.device,
    this.deviceListenable,
    this.style = 'default',
    this.deviceStyles,
    this.assetRoot = defaultAssetRoot,
    this.reverseAxes = false,
    this.mappedKeyboardKey,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  }) : assert(device == null || deviceListenable == null);

  final String input;

  /// Forces a fixed device family and disables automatic input tracking.
  final String? forceDeviceType;

  /// Device family used when automatic input comes from an unrecognized
  /// controller. It also supplies the initial automatic display.
  final String defaultDeviceType;

  /// A fixed device profile for prompts that do not need to listen for input.
  final String? device;

  /// A shared last-input state, normally an [InputDeviceTracker].
  final ValueListenable<String>? deviceListenable;

  /// The preferred style subfolder for all hardware.
  ///
  /// The string is matched directly against a style folder beneath the active
  /// hardware folder. The `default` style uses files directly in the hardware
  /// folder; named styles use a subfolder and fall back to the hardware root.
  final String style;

  /// Retained as an ignored compatibility parameter. Use [style] instead.
  final Object? deviceStyles;

  /// Root directory containing hardware/style asset folders.
  final String assetRoot;

  final bool reverseAxes;
  final String? mappedKeyboardKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  /// Returns the package asset used for a prompt configuration.
  static String assetPathFor({
    required String input,
    required String device,
    String style = 'default',
    String assetRoot = 'assets/input_prompt',
    bool reverseAxes = false,
    String? mappedKeyboardKey,
  }) {
    final paths = assetPathsFor(
      input: input,
      device: device,
      style: style,
      assetRoot: assetRoot,
      reverseAxes: reverseAxes,
      mappedKeyboardKey: mappedKeyboardKey,
    );
    return paths.isEmpty ? '' : paths.first;
  }

  /// Returns the requested style path followed by the hardware-root path when
  /// a named style is requested.
  static List<String> assetPathsFor({
    required String input,
    required String device,
    String style = 'default',
    String assetRoot = 'assets/input_prompt',
    bool reverseAxes = false,
    String? mappedKeyboardKey,
  }) {
    final key = reverseAxes ? _reverseAxis(input) : input;
    final requestedKey = device == 'Keyboard' && mappedKeyboardKey != null
        ? mappedKeyboardKey
        : key;
    final keyName = requestedKey.contains('.')
        ? requestedKey
        : _snakeCase(requestedKey);

    final requestedStyle = style;
    final requestedPaths = _assetPathsForStyle(
      device: device,
      style: requestedStyle,
      assetRoot: assetRoot,
      keyName: keyName,
    );
    if (requestedStyle == 'default') return requestedPaths;

    return <String>[
      ...requestedPaths,
      ..._assetPathsForStyle(
        device: device,
        style: 'default',
        assetRoot: assetRoot,
        keyName: keyName,
      ),
    ];
  }

  static List<String> _assetPathsForStyle({
    required String device,
    required String style,
    required String assetRoot,
    required String keyName,
  }) {
    final extension = keyName.contains('.')
        ? <String>['']
        : const <String>[
            '.svg',
            '.png',
            '.webp',
            '.gif',
            '.apng',
            '.jpg',
            '.jpeg',
          ];
    final stylePath = style == 'default' ? '' : '/$style';
    return extension
        .map((suffix) => '$assetRoot/${device}$stylePath/$keyName$suffix')
        .toList(growable: false);
  }

  static String _snakeCase(String value) {
    var result = value.replaceAllMapped(
      RegExp(r'([A-Z]+)([A-Z][a-z])'),
      (match) => '${match[1]}_${match[2]}',
    );
    result = result.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (match) => '${match[1]}_${match[2]}',
    );
    return result
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '')
        .toLowerCase();
  }

  @override
  State<GamepadGlyph> createState() => _GamepadGlyphState();

  static String _reverseAxis(String input) {
    switch (input) {
      case 'dPadUpDown':
        return 'dPadLeftRight';
      case 'dPadLeftRight':
        return 'dPadUpDown';
      case 'leftThumbstickLeftRight':
        return 'leftThumbstickUpDown';
      case 'leftThumbstickUpDown':
        return 'leftThumbstickLeftRight';
      case 'rightThumbstickLeftRight':
        return 'rightThumbstickUpDown';
      case 'rightThumbstickUpDown':
        return 'rightThumbstickLeftRight';
      default:
        return input;
    }
  }
}

class _GamepadGlyphState extends State<GamepadGlyph> {
  static final _automaticTracker = InputDeviceTracker(initial: 'Xbox One');
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
    final fixedDevice = fixedType == null ? widget.device : fixedType;
    final listenable = fixedType == null
        ? widget.deviceListenable ??
              (_shouldUseAutomaticTracking ? _automaticTracker : null)
        : null;

    if (listenable == null) {
      return _buildGlyph(fixedDevice ?? 'Keyboard');
    }

    return ValueListenableBuilder<String>(
      valueListenable: listenable,
      builder: (context, currentDevice, child) => _buildGlyph(
        currentDevice.isEmpty ? widget.defaultDeviceType : currentDevice,
      ),
    );
  }

  Widget _buildGlyph(String currentDevice) {
    final paths = GamepadGlyph.assetPathsFor(
      input: widget.input,
      device: currentDevice,
      style: widget.style,
      assetRoot: widget.assetRoot,
      reverseAxes: widget.reverseAxes,
      mappedKeyboardKey: widget.mappedKeyboardKey,
    );
    if (paths.isEmpty) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    return FutureBuilder<Uint8List?>(
      future: _loadFirstAsset(
        paths,
        usePluginAssets: widget.assetRoot == GamepadGlyph.defaultAssetRoot,
      ),
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
            semanticsLabel: '${currentDevice} ${widget.input} input',
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
          semanticLabel: '${currentDevice} ${widget.input} input',
        );
      },
    );
  }

  static Future<Uint8List?> _loadFirstAsset(
    Iterable<String> paths, {
    required bool usePluginAssets,
  }) async {
    for (final path in paths) {
      try {
        final assetPath = usePluginAssets
            ? 'packages/gamepad_glyphs/$path'
            : path;
        final data = await rootBundle.load(assetPath);
        return data.buffer.asUint8List();
      } catch (_) {
        // A style may not exist for this hardware. Try its default style next.
      }
    }
    return null;
  }
}
