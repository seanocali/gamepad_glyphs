# gamepad_glyphs

Display keyboard and controller glyphs based on the last input device.

## Initial usage

The default output type is automatic. The glyphs share one internal input
listener, which starts only while an automatic glyph is mounted:

```dart
GamepadGlyph(
  input: GamepadInputType.south,
  width: 48,
  height: 48,
);
```

To always show one specific device family, choose `forceDeviceType`. This does not
start the internal input listener:

```dart
GamepadGlyph(
  input: GamepadInputType.south,
  forceDeviceType: GamepadDevice.ps5,
);
```

When automatic input comes from an unrecognized controller, the default
display is Xbox One. Override that fallback with `defaultDeviceType`.

```dart
GamepadGlyph(
  input: GamepadInputType.south,
  defaultDeviceType: GamepadDevice.ps5,
);
```

## Customize mappings

The mapping is centralized in `defaultInputGlyphs`. Create an app-owned table
when your keyboard bindings differ from the defaults, then pass it to each
prompt:

```dart
final glyphs = defaultInputGlyphs.withKeyboardOverrides({
  GamepadInputType.south: 'Space.svg',
  GamepadInputType.east: 'Escape.svg',
});

GamepadGlyph(
  input: GamepadInputType.south,
  glyphs: glyphs,
);
```

Controller mappings remain unchanged by keyboard overrides. For more advanced
customization, construct an `InputGlyphTable` with customized
`Hardware` entries. Each hardware entry contains a style folder and a map from
`GamepadInputType` to the exact asset filename, including its extension.

Applications can keep their mappings in YAML instead of Dart:

```yaml
hardware:
  xboxOne:
    style: default
    glyphMap:
      south: Xbox One-A.svg
      north: Xbox One-Y.svg
      menu: Xbox One-Start.svg
      homeButton: confirm.webp
```

Declare that YAML and its image files in the application `pubspec.yaml`, then
load it before building prompts:

```dart
final glyphs = await InputGlyphTable.fromAsset(
  'assets/gamepad_glyphs.yaml',
);
```

Pass `glyphs: glyphs` to `GamepadGlyph`. Set `assetRoot` to the application
asset directory and `assetPackage: null` when the mapped files are not part of
this package:

```dart
GamepadGlyph(
  input: GamepadInputType.south,
  glyphs: glyphs,
  assetRoot: 'assets/my_gamepad_glyphs',
  assetPackage: null,
);
```

Mapping values are used verbatim; the loader does not append `.svg` or rewrite
filenames. SVG and raster image formats are supported.

## Styles

Glyph assets are organized as `assets/input_prompt/<hardware>/<style>/`. The
default style is always named `default`. Request an alternate style by its
folder name; if that hardware does not provide it, `GamepadGlyph` silently
uses its `default` style instead. If neither asset exists, the widget displays
nothing.

```dart
GamepadGlyph(
  input: GamepadInputType.south,
  style: 'MonochromeDark',
)
```

Use `deviceStyles` when different hardware should prefer different styles.
Those values take precedence over `style`.

```dart
GamepadGlyph(
  input: GamepadInputType.south,
  deviceStyles: {
    GamepadDevice.keyboard: 'MonochromeLight',
    GamepadDevice.ps5: 'MonochromeDark',
  },
)
```

Styles are just folder names, so package maintainers can add a style folder
without changing Dart code. Flutter bundles only explicitly declared asset
folders, so add the new style folder to the `flutter/assets` list in
`pubspec.yaml` as well. `MonochromeDark` and `MonochromeLight` are regular
optional styles where the relevant hardware provides them; they are no longer a
global rendering mode.

The Windows implementation listens for raw keyboard and HID controller input,
with XInput fallback detection for Xbox controllers.
Other platforms currently retain the manual update API until their native input
sources are implemented.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

