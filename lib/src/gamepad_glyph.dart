import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'input_types.dart';
import '../gamepad_glyphs_platform_interface.dart';

/// Displays the glyph for a generic input on the last-used device.
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

  /// Generic input name. A folder's optional `map.conf` resolves this name to
  /// the native asset filename for that device.
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
  /// A named style without its own `map.conf` inherits the hardware root map.
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
        .map((suffix) => '$assetRoot/$device$stylePath/$keyName$suffix')
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
      case 'dpUpDown':
        return 'dpLeftRight';
      case 'dpLeftRight':
        return 'dpUpDown';
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
  static final _glyphMaps = <String, _GlyphMap>{};
  static final _glyphMapLoads = <String, Future<_GlyphMap>>{};
  static final _assetManifest = AssetManifest.loadFromAssetBundle(rootBundle);
  static final _resolvedAssetPaths = <String, String>{};

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
      _automaticSubscription = GamepadGlyphsPlatform.instance
          .inputEvents()
          .listen((event) {
            _automaticTracker.updateHardwareIds(
              event.vendorId,
              event.productId,
              inputKind: event.kind,
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
    final fixedDevice = fixedType ?? widget.device;
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
    return FutureBuilder<_LoadedGlyph?>(
      future: _loadGlyph(
        input: widget.input,
        device: currentDevice,
        style: widget.style,
        assetRoot: widget.assetRoot,
        reverseAxes: widget.reverseAxes,
        mappedKeyboardKey: widget.mappedKeyboardKey,
      ),
      builder: (context, snapshot) {
        final glyph = snapshot.data;
        if (glyph == null) {
          return SizedBox(width: widget.width, height: widget.height);
        }

        if (glyph.path.toLowerCase().endsWith('.svg')) {
          return SvgPicture.memory(
            glyph.bytes,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            alignment: widget.alignment,
            errorBuilder: (context, error, stackTrace) =>
                SizedBox(width: widget.width, height: widget.height),
            semanticsLabel: '$currentDevice ${widget.input} input',
          );
        }
        return Image.memory(
          glyph.bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          errorBuilder: (context, error, stackTrace) =>
              SizedBox(width: widget.width, height: widget.height),
          semanticLabel: '$currentDevice ${widget.input} input',
        );
      },
    );
  }

  static Future<_LoadedGlyph?> _loadGlyph({
    required String input,
    required String device,
    required String style,
    required String assetRoot,
    required bool reverseAxes,
    required String? mappedKeyboardKey,
  }) async {
    final key = reverseAxes ? GamepadGlyph._reverseAxis(input) : input;
    final requestedKey = device == 'Keyboard' && mappedKeyboardKey != null
        ? mappedKeyboardKey
        : key;
    final genericName = requestedKey.contains('.')
        ? requestedKey
        : GamepadGlyph._snakeCase(requestedKey);
    final styles = style == 'default'
        ? <String>['default']
        : <String>[style, 'default'];
    final usePluginAssets = assetRoot == GamepadGlyph.defaultAssetRoot;
    final rootGlyphMap = await _loadGlyphMap(
      _assetFolder(assetRoot: assetRoot, device: device, style: 'default'),
      usePluginAssets,
    );

    for (final candidateStyle in styles) {
      final folder = _assetFolder(
        assetRoot: assetRoot,
        device: device,
        style: candidateStyle,
      );
      final styleGlyphMap = candidateStyle == 'default'
          ? rootGlyphMap
          : await _loadGlyphMap(folder, usePluginAssets);
      final glyphMap = styleGlyphMap.exists
          ? styleGlyphMap.entries
          : rootGlyphMap.entries;
      final assetName = glyphMap[genericName] ?? genericName;
      final paths = GamepadGlyph._assetPathsForStyle(
        device: device,
        style: candidateStyle,
        assetRoot: assetRoot,
        keyName: assetName,
      );

      for (final path in paths) {
        final bytes = await _loadAsset(path, usePluginAssets: usePluginAssets);
        if (bytes != null) return _LoadedGlyph(path, bytes);
      }
    }
    return null;
  }

  static String _assetFolder({
    required String assetRoot,
    required String device,
    required String style,
  }) => '$assetRoot/$device${style == 'default' ? '' : '/$style'}';

  static Future<_GlyphMap> _loadGlyphMap(String folder, bool usePluginAssets) {
    final cachedMap = _glyphMaps[folder];
    if (cachedMap != null) return Future.value(cachedMap);

    final loadingMap = _glyphMapLoads.putIfAbsent(folder, () async {
      final contents = await _loadAsset(
        '$folder/map.conf',
        usePluginAssets: usePluginAssets,
      );
      if (contents == null) {
        return const _GlyphMap(exists: false, entries: <String, String>{});
      }
      return _GlyphMap(
        exists: true,
        entries: _parseGlyphMap(String.fromCharCodes(contents)),
      );
    });

    return loadingMap.then((map) {
      _glyphMapLoads.remove(folder);
      _glyphMaps[folder] = map;
      return map;
    });
  }

  static Map<String, String> _parseGlyphMap(String contents) {
    final result = <String, String>{};
    for (final rawLine in contents.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final separator = line.indexOf('=');
      if (separator <= 0 || separator == line.length - 1) continue;
      final assetName = line.substring(0, separator).trim();
      final genericName = GamepadGlyph._snakeCase(
        line.substring(separator + 1).trim(),
      );
      if (assetName.isEmpty || genericName.isEmpty) continue;
      result.putIfAbsent(genericName, () => assetName);
    }
    return result;
  }

  static Future<Uint8List?> _loadAsset(
    String path, {
    required bool usePluginAssets,
  }) async {
    try {
      final assetPath = usePluginAssets
          ? 'packages/gamepad_glyphs/$path'
          : path;
      final resolvedPath = await _resolveAssetPath(assetPath);
      final data = await rootBundle.load(resolvedPath);
      return data.buffer.asUint8List();
    } catch (_) {
      // The file is optional; callers provide the fallback order.
    }
    return null;
  }

  static Future<String> _resolveAssetPath(String assetPath) async {
    final normalizedPath = assetPath.toLowerCase();
    return _resolvedAssetPaths[normalizedPath] ??= (await _assetManifest)
        .listAssets()
        .firstWhere(
          (candidate) => candidate.toLowerCase() == normalizedPath,
          orElse: () => assetPath,
        );
  }
}

class _LoadedGlyph {
  const _LoadedGlyph(this.path, this.bytes);

  final String path;
  final Uint8List bytes;
}

class _GlyphMap {
  const _GlyphMap({required this.exists, required this.entries});

  final bool exists;
  final Map<String, String> entries;
}
