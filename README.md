# gamepad_glyphs

Display keyboard and controller glyphs based on the last input device.

## Initial usage

Create one tracker for the prompts in a screen, update it when your input
layer observes a device, and share it with each `InputPrompt`:

```dart
final inputDevices = InputDeviceTracker();

InputPrompt(
  input: GamepadInputType.a,
  deviceListenable: inputDevices,
  width: 48,
  height: 48,
);

// Keyboard, Xbox One, or PlayStation 4 can also be selected directly:
inputDevices.updateHardwareIds(1118, 721);
inputDevices.updateHardwareIds(1356, 1476);
inputDevices.updateHardwareIds(null, null);
```

The first port includes the semantic input mapping and bundled SVG glyphs.
Platform-specific input polling will be added on top of this API.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

