import 'gamepad_glyphs_platform_interface.dart';
import 'src/input_types.dart';
export 'src/input_glyph_table.dart';
export 'src/gamepad_glyph.dart';
export 'src/input_types.dart';

class GamepadGlyphs {
  GamepadGlyphs({
    InputDeviceTracker? inputDevices,
    bool detectMouse = false,
    bool detectTouch = false,
  }) : inputDevices =
           inputDevices ??
           InputDeviceTracker(
             detectMouse: detectMouse,
             detectTouch: detectTouch,
           );

  /// Shared last-input state for prompts owned by this plugin instance.
  final InputDeviceTracker inputDevices;

  Future<String?> getPlatformVersion() {
    return GamepadGlyphsPlatform.instance.getPlatformVersion();
  }

  /// Starts updating [inputDevices] from the current platform's input events.
  void startInputTracking() {
    inputDevices.bind(
      GamepadGlyphsPlatform.instance.inputEvents(
        detectMouse: inputDevices.detectMouse,
        detectTouch: inputDevices.detectTouch,
      ),
    );
  }

  /// Stops updating [inputDevices] from platform input events.
  void stopInputTracking() {
    inputDevices.unbind();
  }
}
