import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamepad_glyphs/gamepad_glyphs.dart';

void main() {
  test('maps the example action to each device family', () {
    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.south,
        device: const InputDeviceProfile.keyboard(),
      ),
      'assets/input_prompt/Keyboard/Light/Enter.svg',
    );
    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.south,
        device: const InputDeviceProfile(InputDeviceModel.xboxOne),
      ),
      'assets/input_prompt/Microsoft/Xbox One-A.svg',
    );
    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.south,
        device: const InputDeviceProfile(InputDeviceModel.ps4),
      ),
      'assets/input_prompt/Sony/PS4-Cross.svg',
    );
  });

  test('uses controller-agnostic face-button semantics', () {
    expect(
      defaultInputGlyphs.glyphName(
        GamepadInputType.north,
        InputDeviceModel.xboxOne,
      ),
      'Y',
    );
    expect(
      defaultInputGlyphs.glyphName(
        GamepadInputType.north,
        InputDeviceModel.ps4,
      ),
      'Triangle',
    );
    expect(
      defaultInputGlyphs.glyphName(
        GamepadInputType.south,
        InputDeviceModel.ps4,
      ),
      'Cross',
    );
    expect(
      defaultInputGlyphs.glyphName(GamepadInputType.east, InputDeviceModel.ps4),
      'Circle',
    );
    expect(
      defaultInputGlyphs.glyphName(GamepadInputType.west, InputDeviceModel.ps4),
      'Square',
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

  test('tracker can consume platform input events', () async {
    final tracker = InputDeviceTracker();
    tracker.bind(
      Stream<InputDeviceEvent>.value(
        const InputDeviceEvent(vendorId: 1356, productId: 1476),
      ),
    );

    await Future<void>.delayed(Duration.zero);
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
        input: GamepadInputType.south,
        device: const InputDeviceProfile.keyboard(),
        mappedKeyboardKey: 'Space',
      ),
      'assets/input_prompt/Keyboard/Light/Space.svg',
    );
  });

  test('resolves monochrome keyboard glyph assets', () {
    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.south,
        device: const InputDeviceProfile.keyboard(),
        useMonochrome: true,
      ),
      'assets/input_prompt/Keyboard/MonochromeLight/Enter.svg',
    );
    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.south,
        device: const InputDeviceProfile.keyboard(),
        theme: InputPromptTheme.dark,
        useMonochrome: true,
      ),
      'assets/input_prompt/Keyboard/MonochromeDark/Enter.svg',
    );
  });

  test('resolves controller monochrome glyph assets', () {
    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.south,
        device: const InputDeviceProfile(InputDeviceModel.xboxOne),
        useMonochrome: true,
      ),
      'assets/input_prompt/Monochrome/Xbox/0.svg',
    );
    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.south,
        device: const InputDeviceProfile(InputDeviceModel.ps5),
        useMonochrome: true,
      ),
      'assets/input_prompt/Monochrome/PlayStation/0.svg',
    );
  });

  test('allows keyboard mappings to be customized in one table', () {
    final customGlyphs = defaultInputGlyphs.withKeyboardOverrides({
      GamepadInputType.south: 'Space',
      GamepadInputType.east: 'Escape',
    });

    expect(
      customGlyphs.glyphName(GamepadInputType.south, InputDeviceModel.keyboard),
      'Space',
    );
    expect(
      customGlyphs.glyphName(GamepadInputType.south, InputDeviceModel.xboxOne),
      'A',
    );
    expect(
      defaultInputGlyphs.glyphName(
        GamepadInputType.south,
        InputDeviceModel.keyboard,
      ),
      'Enter',
    );
    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.south,
        device: const InputDeviceProfile.keyboard(),
        glyphs: customGlyphs,
      ),
      'assets/input_prompt/Keyboard/Light/Space.svg',
    );
  });

  test('uses available Nintendo Switch glyph names', () {
    const switchDevice = InputDeviceProfile(InputDeviceModel.switchPro);

    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.view,
        device: switchDevice,
      ),
      'assets/input_prompt/Nintendo/Switch-Minus.svg',
    );
    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.menu,
        device: switchDevice,
      ),
      'assets/input_prompt/Nintendo/Switch-Plus.svg',
    );
    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.rightThumbstick,
        device: switchDevice,
      ),
      'assets/input_prompt/Nintendo/Switch-RightThumbStick.svg',
    );
    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.dPad,
        device: switchDevice,
      ),
      isEmpty,
    );
  });

  test('does not request missing keyboard composite glyph assets', () {
    const keyboard = InputDeviceProfile.keyboard();

    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.dPadUpLeft,
        device: keyboard,
      ),
      isEmpty,
    );
    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.leftThumbstickDownRight,
        device: keyboard,
      ),
      isEmpty,
    );
  });

  test('loads the derived PS3 diagonal thumbstick glyph', () {
    expect(
      InputPrompt.assetPathFor(
        input: GamepadInputType.leftThumbstickUpLeft,
        device: const InputDeviceProfile(InputDeviceModel.ps3),
      ),
      'assets/input_prompt/Sony/PS3-LeftThumbstickUpLeft.svg',
    );
  });

  test('every default mapping points to an existing bundled asset', () {
    final missing = <String>[];
    const auditedModels = <InputDeviceModel>[
      InputDeviceModel.keyboard,
      InputDeviceModel.xbox360,
      InputDeviceModel.xboxOne,
      InputDeviceModel.xboxSeriesXs,
      InputDeviceModel.ps3,
      InputDeviceModel.ps4,
      InputDeviceModel.ps5,
      InputDeviceModel.switchPro,
    ];
    for (final entry in defaultInputGlyphs.rows.entries) {
      for (final model in auditedModels) {
        final path = InputPrompt.assetPathFor(
          input: entry.key,
          device: InputDeviceProfile(model),
        );
        if (path.isEmpty) continue;

        final asset = File(path);
        if (!asset.existsSync() || asset.lengthSync() == 0) {
          missing.add('${entry.key.name} / ${model.name} -> $path');
        }
      }
    }
    expect(missing, isEmpty, reason: missing.join('\n'));
  });
}
