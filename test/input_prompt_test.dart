import 'package:flutter_test/flutter_test.dart';
import 'package:gamepad_glyphs/gamepad_glyphs.dart';

void main() {
  test('maps the example action to each device family', () {
    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.a,
        device: const InputDeviceProfile.keyboard(),
      ),
      'assets/input_prompt/Keyboard/Light/Enter.svg',
    );
    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.a,
        device: const InputDeviceProfile(InputDeviceModel.xboxOne),
      ),
      'assets/input_prompt/Microsoft/Xbox One-A.svg',
    );
    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.a,
        device: const InputDeviceProfile(InputDeviceModel.ps4),
      ),
      'assets/input_prompt/Sony/PS4-Cross.svg',
    );
  });

  test('maps hardware IDs and keyboard fallback', () {
    expect(
      InputDeviceProfile.fromHardwareIds(1118, 702).model,
      InputDeviceModel.xbox360,
    );
    expect(
      InputDeviceProfile.fromHardwareIds(1356, 3302).model,
      InputDeviceModel.ps5,
    );
    expect(
      InputDeviceProfile.fromHardwareIds(null, null).model,
      InputDeviceModel.keyboard,
    );
    expect(
      InputDeviceProfile.fromHardwareIds(9999, 1).model,
      InputDeviceModel.keyboard,
    );
  });

  test('tracker publishes the latest device profile', () {
    final tracker = InputDeviceTracker();
    expect(tracker.value.model, InputDeviceModel.keyboard);

    tracker.updateHardwareIds(1118, 721);
    expect(tracker.value.model, InputDeviceModel.xboxOne);

    tracker.updateHardwareIds(1356, 1476);
    expect(tracker.value.model, InputDeviceModel.ps4);
    tracker.dispose();
  });

  test('reverses composite axes and supports keyboard overrides', () {
    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.leftThumbstickLeftRight,
        device: const InputDeviceProfile.keyboard(),
        reverseAxes: true,
      ),
      'assets/input_prompt/Keyboard/Light/WS.svg',
    );
    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.a,
        device: const InputDeviceProfile.keyboard(),
        mappedKeyboardKey: 'Space',
      ),
      'assets/input_prompt/Keyboard/Light/Space.svg',
    );
  });
}
