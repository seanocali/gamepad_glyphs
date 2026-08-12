import 'package:flutter_test/flutter_test.dart';
import 'package:gamepad_glyphs/gamepad_glyphs.dart';
import 'package:gamepad_glyphs/gamepad_glyphs_platform_interface.dart';
import 'package:gamepad_glyphs/gamepad_glyphs_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGamepadGlyphsPlatform
    with MockPlatformInterfaceMixin
    implements GamepadGlyphsPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Stream<InputDeviceEvent> get inputEvents => const Stream.empty();
}

void main() {
  final GamepadGlyphsPlatform initialPlatform = GamepadGlyphsPlatform.instance;

  test('$MethodChannelGamepadGlyphs is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelGamepadGlyphs>());
  });

  test('getPlatformVersion', () async {
    GamepadGlyphs gamepadGlyphsPlugin = GamepadGlyphs();
    MockGamepadGlyphsPlatform fakePlatform = MockGamepadGlyphsPlatform();
    GamepadGlyphsPlatform.instance = fakePlatform;

    expect(await gamepadGlyphsPlugin.getPlatformVersion(), '42');
  });
}
