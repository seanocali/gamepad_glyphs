@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:gamepad_glyphs/gamepad_glyphs_web.dart';
import 'package:gamepad_glyphs/src/input_types.dart';
import 'package:web/web.dart' as web;

void main() {
  test('emits browser keyboard input', () async {
    final event = GamepadGlyphsWeb().inputEvents().first;

    web.window.dispatchEvent(web.KeyboardEvent('keydown'));

    expect((await event).kind, InputDeviceKind.keyboard);
  });

  test('does not emit pointer input unless requested', () async {
    var emitted = false;
    final subscription = GamepadGlyphsWeb().inputEvents().listen((_) {
      emitted = true;
    });

    web.window.dispatchEvent(
      web.PointerEvent(
        'pointerdown',
        web.PointerEventInit(pointerType: 'mouse'),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(emitted, isFalse);
    await subscription.cancel();
  });

  test('emits opted-in browser pointer input', () async {
    final event = GamepadGlyphsWeb().inputEvents(detectMouse: true).first;

    web.window.dispatchEvent(
      web.PointerEvent(
        'pointerdown',
        web.PointerEventInit(pointerType: 'mouse'),
      ),
    );

    expect((await event).kind, InputDeviceKind.mouse);
  });
}
