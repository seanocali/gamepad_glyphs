import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepad_glyphs/gamepad_glyphs_method_channel.dart';
import 'package:gamepad_glyphs/src/input_types.dart';

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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          const EventChannel('gamepad_glyphs/input_events'),
          null,
        );
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('inputEvents maps native device events', () async {
    final inputChannel = const EventChannel('gamepad_glyphs/input_events');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          inputChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success(<String, int>{'vendorId': 1118, 'productId': 721});
              events.endOfStream();
            },
          ),
        );

    final event = await platform.inputEvents.first;
    expect(event.vendorId, 1118);
    expect(event.productId, 721);
  });

  test('additional device mappings override built-in mappings', () {
    expect(
      deviceFromHardwareIds(
        1118,
        721,
        additionalDevicesMap: <int, Map<int, String>>{
          1118: <int, String>{721: 'My Controller'},
        },
      ),
      'My Controller',
    );
    expect(deviceFromHardwareIds(1118, 721), 'Xbox One');
  });
}
