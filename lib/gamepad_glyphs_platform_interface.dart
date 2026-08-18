import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'gamepad_glyphs_method_channel.dart';
import 'src/input_types.dart';

abstract class GamepadGlyphsPlatform extends PlatformInterface {
  /// Constructs a GamepadGlyphsPlatform.
  GamepadGlyphsPlatform() : super(token: _token);

  static final Object _token = Object();

  static GamepadGlyphsPlatform _instance = MethodChannelGamepadGlyphs();

  /// The default instance of [GamepadGlyphsPlatform] to use.
  ///
  /// Defaults to [MethodChannelGamepadGlyphs].
  static GamepadGlyphsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [GamepadGlyphsPlatform] when
  /// they register themselves.
  static set instance(GamepadGlyphsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Emits the most recently observed input device.
  ///
  /// Mouse and touch input are excluded unless explicitly requested.
  Stream<InputDeviceEvent> inputEvents({
    bool detectMouse = false,
    bool detectTouch = false,
  }) => const Stream.empty();
}
