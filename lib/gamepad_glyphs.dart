import 'gamepad_glyphs_platform_interface.dart';
import 'src/input_types.dart';
export 'src/input_glyph_table.dart';
export 'src/input_prompt.dart';
export 'src/input_types.dart';

class GamepadGlyphs {
  GamepadGlyphs({InputDeviceTracker? inputDevices})
    : inputDevices = inputDevices ?? InputDeviceTracker();

  /// Shared last-input state for prompts owned by this plugin instance.
  final InputDeviceTracker inputDevices;

  Future<String?> getPlatformVersion() {
    return GamepadGlyphsPlatform.instance.getPlatformVersion();
  }

  /// Starts updating [inputDevices] from the current platform's input events.
  void startInputTracking() {
    inputDevices.bind(GamepadGlyphsPlatform.instance.inputEvents);
  }

  /// Stops updating [inputDevices] from platform input events.
  void stopInputTracking() {
    inputDevices.unbind();
  }
}
