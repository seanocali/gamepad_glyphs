import 'package:flutter_test/flutter_test.dart';
import 'package:gamepad_glyphs/src/controller_activity.dart';

void main() {
  test('initial controller state establishes a passive baseline', () {
    final tracker = ControllerActivityTracker();

    expect(
      tracker.update(buttonValues: const [1], axisValues: const [0.04, -0.03]),
      isFalse,
    );
  });

  test('button release is passive and the next press is active', () {
    final tracker = ControllerActivityTracker();
    tracker.update(buttonValues: const [1], axisValues: const [0]);

    expect(
      tracker.update(buttonValues: const [0], axisValues: const [0]),
      isFalse,
    );
    expect(
      tracker.update(buttonValues: const [1], axisValues: const [0]),
      isTrue,
    );
  });

  test('axis noise is passive until movement crosses the dead zone', () {
    final tracker = ControllerActivityTracker();
    tracker.update(buttonValues: const [], axisValues: const [0]);

    expect(
      tracker.update(buttonValues: const [], axisValues: const [0.1]),
      isFalse,
    );
    expect(
      tracker.update(buttonValues: const [], axisValues: const [0.11]),
      isTrue,
    );
  });

  test('slow axis movement accumulates from the last active baseline', () {
    final tracker = ControllerActivityTracker();
    tracker.update(buttonValues: const [], axisValues: const [0]);

    expect(
      tracker.update(buttonValues: const [], axisValues: const [0.06]),
      isFalse,
    );
    expect(
      tracker.update(buttonValues: const [], axisValues: const [0.12]),
      isTrue,
    );
  });
}
