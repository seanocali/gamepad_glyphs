import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'gamepad_glyphs_platform_interface.dart';
import 'src/input_types.dart';

/// An implementation of [GamepadGlyphsPlatform] that uses method channels.
class MethodChannelGamepadGlyphs extends GamepadGlyphsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('gamepad_glyphs');

  @visibleForTesting
  final inputEventChannel = const EventChannel('gamepad_glyphs/input_events');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Stream<InputDeviceEvent> get inputEvents => inputEventChannel
      .receiveBroadcastStream()
      .where((event) => event is Map)
      .map(
        (event) =>
            InputDeviceEvent.fromMap(Map<Object?, Object?>.from(event as Map)),
      );
}
