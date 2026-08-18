import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamepad_glyphs/gamepad_glyphs.dart';
import 'package:gamepad_glyphs/gamepad_glyphs_platform_interface.dart';
import 'package:gamepad_glyphs/gamepad_glyphs_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGamepadGlyphsPlatform
    with MockPlatformInterfaceMixin
    implements GamepadGlyphsPlatform {
  bool? receivedDetectMouse;
  bool? receivedDetectTouch;

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Stream<InputDeviceEvent> inputEvents({
    bool detectMouse = false,
    bool detectTouch = false,
  }) {
    receivedDetectMouse = detectMouse;
    receivedDetectTouch = detectTouch;
    return const Stream.empty();
  }
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

  test('forwards optional pointer detection when tracking starts', () {
    final fakePlatform = MockGamepadGlyphsPlatform();
    GamepadGlyphsPlatform.instance = fakePlatform;
    addTearDown(() => GamepadGlyphsPlatform.instance = initialPlatform);

    GamepadGlyphs(detectMouse: true, detectTouch: true).startInputTracking();

    expect(fakePlatform.receivedDetectMouse, isTrue);
    expect(fakePlatform.receivedDetectTouch, isTrue);
  });

  test('tracker retains the native input kind', () async {
    final events = StreamController<InputDeviceEvent>();
    final tracker = InputDeviceTracker();
    addTearDown(events.close);
    addTearDown(tracker.dispose);
    tracker.bind(events.stream);

    events.add(
      const InputDeviceEvent(
        vendorId: 1234,
        productId: 5678,
        kind: InputDeviceKind.mouse,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(tracker.inputKind, InputDeviceKind.mouse);
    expect(tracker.value, 'Mouse');
  });
}
