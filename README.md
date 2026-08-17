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

## Naming custom glyphs

There is no mapping configuration. Rename each asset to the semantic input it
represents, using the `GamepadInputType` name:

```text
assets/my_gamepad_glyphs/Xbox One/south.svg
assets/my_gamepad_glyphs/Xbox One/menu.webp
assets/my_gamepad_glyphs/Xbox One/l1.svg
assets/my_gamepad_glyphs/Xbox One/l2.svg
assets/my_gamepad_glyphs/Xbox One/l3.svg
```

`GamepadGlyph` probes extensions in this order: `.svg`, `.png`, `.webp`, then
`.gif`, `.apng`, `.jpg`, then `.jpeg`. Animated GIF, WebP, and APNG files are
played by Flutter's image codec. To use application-owned assets, set `assetRoot`:

```dart
GamepadGlyph(
  input: GamepadInputType.south,
  assetRoot: 'assets/my_gamepad_glyphs',
);
```

## Styles

Glyph assets are organized with the default glyphs directly under
`assets/input_prompt/<hardware>/`. Alternate styles are subfolders beneath the
hardware folder. Request an alternate style by its folder name; if that
hardware does not provide it, `GamepadGlyph` silently uses the hardware-root
glyph instead. If neither asset exists, the widget displays nothing.

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

