import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'gamepad_glyphs_platform_interface.dart';

/// An implementation of [GamepadGlyphsPlatform] that uses method channels.
class MethodChannelGamepadGlyphs extends GamepadGlyphsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('gamepad_glyphs');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
