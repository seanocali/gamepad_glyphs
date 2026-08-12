# gamepad_glyphs

Display keyboard and controller glyphs based on the last input device.

## Initial usage

Create one tracker for the prompts in a screen, update it when your input
layer observes a device, and share it with each `InputPrompt`:

```dart
final inputDevices = InputDeviceTracker();
final gamepadGlyphs = GamepadGlyphs(inputDevices: inputDevices);
gamepadGlyphs.startInputTracking();

InputPrompt(
  input: GamepadInputType.south,
  deviceListenable: inputDevices,
  width: 48,
  height: 48,
);

// Keyboard, Xbox One, or PlayStation 4 can also be selected directly:
inputDevices.updateHardwareIds(1118, 721);
inputDevices.updateHardwareIds(1356, 1476);
inputDevices.updateHardwareIds(null, null);

// Call gamepadGlyphs.stopInputTracking() when the owning screen is disposed.
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

InputPrompt(
  input: GamepadInputType.south,
  deviceListenable: inputDevices,
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

