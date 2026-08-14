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
  GamepadInputType.south: 'Space',
  GamepadInputType.east: 'Escape',
});

GamepadGlyph(
  input: GamepadInputType.south,
  glyphs: glyphs,
);
```

Controller mappings remain unchanged by keyboard overrides. For more advanced
customization, construct an `InputGlyphTable` with customized
`InputGlyphRow` values.

The Windows implementation listens for raw keyboard and HID controller input,
with XInput fallback detection for Xbox controllers. Monochrome controller
glyphs are provided as SVG assets converted from the original Xbox and
PlayStation private-use font glyphs.
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

