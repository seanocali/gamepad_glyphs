import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepad_glyphs/gamepad_glyphs_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelGamepadGlyphs platform = MethodChannelGamepadGlyphs();
  const MethodChannel channel = MethodChannel('gamepad_glyphs');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
