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
    Object? receivedArguments;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          inputChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              receivedArguments = arguments;
              events.success(<String, Object>{
                'vendorId': 1118,
                'productId': 721,
                'kind': 'mouse',
              });
              events.endOfStream();
            },
          ),
        );

    final event = await platform
        .inputEvents(detectMouse: true, detectTouch: true)
        .first;
    expect(event.vendorId, 1118);
    expect(event.productId, 721);
    expect(event.kind, InputDeviceKind.mouse);
    expect(receivedArguments, <String, bool>{
      'detectMouse': true,
      'detectTouch': true,
    });
  });

  test('InputDeviceEvent parses every native input kind', () {
    for (final entry in <String, InputDeviceKind>{
      'keyboard': InputDeviceKind.keyboard,
      'mouse': InputDeviceKind.mouse,
      'touch': InputDeviceKind.touch,
      'remote': InputDeviceKind.remote,
      'gamepad': InputDeviceKind.gamepad,
    }.entries) {
      expect(
        InputDeviceEvent.fromMap(<String, Object>{
          'vendorId': 1,
          'productId': 2,
          'kind': entry.key,
        }).kind,
        entry.value,
      );
    }
  });

  test('selects the highest-priority native kind', () {
    expect(
      InputDeviceEvent.fromMap(<String, Object>{
        'vendorId': 1118,
        'productId': 721,
        'kinds': <String>['keyboard', 'gamepad'],
      }).kind,
      InputDeviceKind.gamepad,
    );
    expect(
      InputDeviceEvent.fromMap(<String, Object>{
        'kinds': <String>['keyboard', 'remote'],
      }).kind,
      InputDeviceKind.remote,
    );
    expect(
      deviceFromHardwareIds(null, null, inputKind: InputDeviceKind.gamepad),
      'Xbox One',
    );
  });

  test('maps known Xbox controller IDs to their device families', () {
    expect(
      deviceFromHardwareIds(1118, 654, inputKind: InputDeviceKind.gamepad),
      'Xbox 360',
    );
    expect(
      deviceFromHardwareIds(1118, 721, inputKind: InputDeviceKind.gamepad),
      'Xbox One',
    );
  });

  test('maps the Arcade controller IDs to Arcade', () {
    expect(
      deviceFromHardwareIds(3090, 3120, inputKind: InputDeviceKind.gamepad),
      'Arcade',
    );
  });

  test('maps mouse and touch input by their native category', () {
    expect(
      deviceFromHardwareIds(1133, 49274, inputKind: InputDeviceKind.mouse),
      'Mouse',
    );
    expect(
      deviceFromHardwareIds(null, null, inputKind: InputDeviceKind.touch),
      'Touch',
    );
  });

  test('maps remote and Apple product categories to remote glyph folders', () {
    expect(
      deviceFromHardwareIds(6353, 945, inputKind: InputDeviceKind.remote),
      'Google TV',
    );
    expect(
      deviceFromHardwareIds(7439, null, inputKind: InputDeviceKind.remote),
      'Fire TV',
    );
    expect(
      deviceFromHardwareIds(null, null, inputKind: InputDeviceKind.remote),
      'TV Remote',
    );
    expect(
      deviceFromProductCategory('GCProductCategorySiriRemote2ndGen'),
      'Apple TV',
    );
  });

  test('maps the recovered Luna and SNES hardware IDs', () {
    expect(
      deviceFromHardwareIds(7439, 369, inputKind: InputDeviceKind.gamepad),
      'Luna',
    );
    expect(
      deviceFromHardwareIds(11720, 24577, inputKind: InputDeviceKind.gamepad),
      'SNES',
    );
  });
}
