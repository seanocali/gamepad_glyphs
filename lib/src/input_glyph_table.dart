import 'input_types.dart';
import 'default_mapping.g.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

/// The asset style and exact asset filenames for one hardware family.
class Hardware {
  const Hardware({required this.style, required this.glyphMap});

  final String style;
  final Map<GamepadInputType, String> glyphMap;
}

/// The glyph mappings for all supported hardware families.
class InputGlyphTable {
  const InputGlyphTable({required this.hardware});

  /// Parses an app-owned YAML mapping.
  ///
  /// Values in `glyphMap` are used verbatim as asset filenames, including
  /// their extensions. For example, `confirm.svg` and `confirm.webp` are both
  /// valid values.
  factory InputGlyphTable.fromYaml(String source) {
    final document = loadYaml(source);
    if (document is! YamlMap || document['hardware'] is! YamlMap) {
      throw const FormatException('YAML must contain a hardware map.');
    }

    final hardware = <GamepadDevice, Hardware>{};
    for (final entry in (document['hardware'] as YamlMap).entries) {
      final device = _deviceFromYamlKey(entry.key);
      final value = entry.value;
      if (value is! YamlMap || value['glyphMap'] is! YamlMap) {
        throw FormatException('Hardware $entry must contain glyphMap.');
      }

      final glyphMap = <GamepadInputType, String>{};
      for (final glyph in (value['glyphMap'] as YamlMap).entries) {
        final input = _inputFromYamlKey(glyph.key);
        if (glyph.value is! String || (glyph.value as String).isEmpty) {
          throw FormatException('Glyph for ${glyph.key} must be a filename.');
        }
        glyphMap[input] = glyph.value as String;
      }
      hardware[device] = Hardware(
        style: value['style'] as String? ?? 'default',
        glyphMap: Map.unmodifiable(glyphMap),
      );
    }
    return InputGlyphTable(hardware: Map.unmodifiable(hardware));
  }

  /// Loads an app-owned YAML mapping from an application asset.
  static Future<InputGlyphTable> fromAsset(String assetPath) async {
    return InputGlyphTable.fromYaml(await rootBundle.loadString(assetPath));
  }

  final Map<GamepadDevice, Hardware> hardware;

  String? glyphName(GamepadInputType input, GamepadDevice device) =>
      hardware[device]?.glyphMap[input];

  String styleFor(GamepadDevice device) => hardware[device]?.style ?? 'default';

  Iterable<GamepadInputType> get inputs =>
      hardware.values.expand((entry) => entry.glyphMap.keys).toSet();

  /// Returns a table with the selected keyboard mappings changed.
  InputGlyphTable withKeyboardOverrides(
    Map<GamepadInputType, String> overrides,
  ) {
    final keyboard = hardware[GamepadDevice.keyboard];
    if (keyboard == null || overrides.isEmpty) return this;

    final glyphMap = <GamepadInputType, String>{...keyboard.glyphMap};
    glyphMap.addAll(overrides);
    return InputGlyphTable(
      hardware: <GamepadDevice, Hardware>{
        ...hardware,
        GamepadDevice.keyboard: Hardware(
          style: keyboard.style,
          glyphMap: Map.unmodifiable(glyphMap),
        ),
      },
    );
  }
}

GamepadDevice _deviceFromYamlKey(Object? key) {
  final name = key.toString();
  return GamepadDevice.values.firstWhere(
    (device) => device.name == name,
    orElse: () => throw FormatException('Unknown hardware: $name'),
  );
}

GamepadInputType _inputFromYamlKey(Object? key) {
  final name = key.toString();
  return GamepadInputType.values.firstWhere(
    (input) => input.name == name,
    orElse: () => throw FormatException('Unknown input: $name'),
  );
}

/// The package's default hardware mappings loaded from the YAML source.
final defaultInputGlyphs = InputGlyphTable.fromYaml(defaultMappingYaml);
