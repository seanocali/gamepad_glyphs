import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepad_glyphs/gamepad_glyphs.dart';

void main() {
  test('loads exact asset filenames from YAML', () {
    final glyphs = InputGlyphTable.fromYaml('''
hardware:
  xboxOne:
    style: custom
    glyphMap:
      south: confirm.webp
      menu: start.svg
''');

    expect(
      glyphs.glyphName(GamepadInputType.south, GamepadDevice.xboxOne),
      'confirm.webp',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.south,
        device: const InputDeviceProfile(GamepadDevice.xboxOne),
        glyphs: glyphs,
        assetRoot: 'assets/custom',
      ),
      'assets/custom/Xbox One/custom/confirm.webp',
    );
  });

  test('maps the example action to each device family', () {
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.south,
        device: const InputDeviceProfile.keyboard(),
      ),
      'assets/input_prompt/Keyboard/default/Space.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.south,
        device: const InputDeviceProfile(GamepadDevice.xboxOne),
      ),
      'assets/input_prompt/Xbox One/default/Xbox One-A.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.south,
        device: const InputDeviceProfile(GamepadDevice.ps4),
      ),
      'assets/input_prompt/PS4/default/PS4-Cross.svg',
    );
  });

  test('uses controller-agnostic face-button semantics', () {
    expect(
      defaultInputGlyphs.glyphName(
        GamepadInputType.north,
        GamepadDevice.xboxOne,
      ),
      'Y',
    );
    expect(
      defaultInputGlyphs.glyphName(GamepadInputType.north, GamepadDevice.ps4),
      'Triangle',
    );
    expect(
      defaultInputGlyphs.glyphName(GamepadInputType.south, GamepadDevice.ps4),
      'Cross',
    );
    expect(
      defaultInputGlyphs.glyphName(GamepadInputType.east, GamepadDevice.ps4),
      'Circle',
    );
    expect(
      defaultInputGlyphs.glyphName(GamepadInputType.west, GamepadDevice.ps4),
      'Square',
    );
  });

  test('maps the available Arcade buttons', () {
    const arcade = GamepadDevice.arcade;
    const expected = <GamepadInputType, String>{
      GamepadInputType.west: 'B1',
      GamepadInputType.north: 'B2',
      GamepadInputType.rightShoulder: 'B3',
      GamepadInputType.leftRightShoulder: 'B3B7',
      GamepadInputType.south: 'B4',
      GamepadInputType.east: 'B5',
      GamepadInputType.rightTrigger: 'B6',
      GamepadInputType.leftRightTrigger: 'B6B8',
      GamepadInputType.leftShoulder: 'B7',
      GamepadInputType.leftTrigger: 'B8',
      GamepadInputType.leftThumbstickButton: 'B9',
      GamepadInputType.rightThumbstickButton: 'B10',
      GamepadInputType.homeButton: 'Home',
    };

    for (final entry in expected.entries) {
      expect(defaultInputGlyphs.glyphName(entry.key, arcade), entry.value);
      expect(
        GamepadGlyph.assetPathFor(
          input: entry.key,
          device: const InputDeviceProfile(arcade),
        ),
        'assets/input_prompt/Arcade/default/${entry.value}.svg',
      );
    }
  });

  test('maps Arcade controls to the available glyph families', () {
    const arcade = GamepadDevice.arcade;
    const expected = <GamepadInputType, String>{
      GamepadInputType.view: 'Insert Coin Button',
      GamepadInputType.menu: 'Player 1 Start',
      GamepadInputType.dPad: 'Stick',
      GamepadInputType.dPadUp: 'StickUp',
      GamepadInputType.dPadDown: 'StickDown',
      GamepadInputType.dPadLeft: 'StickLeft',
      GamepadInputType.dPadRight: 'StickRight',
      GamepadInputType.dPadUpLeft: 'StickUpLeft',
      GamepadInputType.dPadDownRight: 'StickDownRight',
      GamepadInputType.dPadDownLeft: 'StickDownLeft',
      GamepadInputType.dPadUpRight: 'StickUpRight',
      GamepadInputType.dPadUpDown: 'StickUpDown',
      GamepadInputType.dPadLeftRight: 'StickLeftRight',
      GamepadInputType.leftThumbstick: 'Stick',
      GamepadInputType.leftThumbstickClockwise: 'StickRotateClockwise',
      GamepadInputType.leftThumbstickCounterclockwise:
          'StickRotateCounterclockwise',
      GamepadInputType.leftThumbstickUp: 'StickUp',
      GamepadInputType.leftThumbstickDown: 'StickDown',
      GamepadInputType.leftThumbstickLeft: 'StickLeft',
      GamepadInputType.leftThumbstickRight: 'StickRight',
      GamepadInputType.leftThumbstickUpLeft: 'StickUpLeft',
      GamepadInputType.leftThumbstickDownRight: 'StickDownRight',
      GamepadInputType.leftThumbstickDownLeft: 'StickDownLeft',
      GamepadInputType.leftThumbstickUpRight: 'StickUpRight',
      GamepadInputType.leftThumbstickLeftRight: 'StickLeftRight',
      GamepadInputType.leftThumbstickUpDown: 'StickUpDown',
      GamepadInputType.rightThumbstick: 'Trackball',
      GamepadInputType.rightThumbstickClockwise: 'SpinnerRotateClockwise',
      GamepadInputType.rightThumbstickCounterclockwise:
          'SpinnerRotateCounterclockwise',
      GamepadInputType.rightThumbstickUp: 'TrackballUp',
      GamepadInputType.rightThumbstickDown: 'TrackballDown',
      GamepadInputType.rightThumbstickLeft: 'TrackballLeft',
      GamepadInputType.rightThumbstickRight: 'TrackballRight',
      GamepadInputType.rightThumbstickUpLeft: 'TrackballUpLeft',
      GamepadInputType.rightThumbstickDownRight: 'TrackballDownRight',
      GamepadInputType.rightThumbstickDownLeft: 'TrackballDownLeft',
      GamepadInputType.rightThumbstickUpRight: 'TrackballUpRight',
      GamepadInputType.rightThumbstickLeftRight: 'TrackballLeftRight',
      GamepadInputType.rightThumbstickUpDown: 'TrackballUpDown',
    };

    for (final entry in expected.entries) {
      expect(defaultInputGlyphs.glyphName(entry.key, arcade), entry.value);
    }
  });

  test('uses the default keyboard mapping', () {
    const keyboard = GamepadDevice.keyboard;

    expect(
      defaultInputGlyphs.glyphName(GamepadInputType.south, keyboard),
      'Space',
    );
    expect(defaultInputGlyphs.glyphName(GamepadInputType.east, keyboard), 'C');
    expect(defaultInputGlyphs.glyphName(GamepadInputType.west, keyboard), 'R');
    expect(defaultInputGlyphs.glyphName(GamepadInputType.north, keyboard), 'X');
    expect(
      defaultInputGlyphs.glyphName(GamepadInputType.leftShoulder, keyboard),
      'Q',
    );
    expect(
      defaultInputGlyphs.glyphName(GamepadInputType.rightShoulder, keyboard),
      'G',
    );
    expect(
      defaultInputGlyphs.glyphName(GamepadInputType.leftTrigger, keyboard),
      'Divide',
    );
    expect(
      defaultInputGlyphs.glyphName(GamepadInputType.rightTrigger, keyboard),
      'Enter',
    );
    expect(
      defaultInputGlyphs.glyphName(
        GamepadInputType.leftThumbstickButton,
        keyboard,
      ),
      'Shift',
    );
    expect(
      defaultInputGlyphs.glyphName(
        GamepadInputType.rightThumbstickButton,
        keyboard,
      ),
      'V',
    );
    expect(
      defaultInputGlyphs.glyphName(GamepadInputType.view, keyboard),
      'RightShift',
    );
    expect(
      defaultInputGlyphs.glyphName(GamepadInputType.menu, keyboard),
      'Enter',
    );
    expect(
      defaultInputGlyphs.glyphName(GamepadInputType.dPadUp, keyboard),
      'Up',
    );
    expect(
      defaultInputGlyphs.glyphName(GamepadInputType.dPadDown, keyboard),
      'Down',
    );
    expect(
      defaultInputGlyphs.glyphName(GamepadInputType.dPadLeft, keyboard),
      'Left',
    );
    expect(
      defaultInputGlyphs.glyphName(GamepadInputType.dPadRight, keyboard),
      'Right',
    );
    expect(
      defaultInputGlyphs.glyphName(GamepadInputType.homeButton, keyboard),
      'F1',
    );
    expect(
      defaultInputGlyphs.glyphName(
        GamepadInputType.rightThumbstickUpLeft,
        keyboard,
      ),
      '84',
    );
    expect(
      defaultInputGlyphs.glyphName(
        GamepadInputType.rightThumbstickUpRight,
        keyboard,
      ),
      '86',
    );
    expect(
      defaultInputGlyphs.glyphName(
        GamepadInputType.rightThumbstickDownLeft,
        keyboard,
      ),
      '42',
    );
    expect(
      defaultInputGlyphs.glyphName(
        GamepadInputType.rightThumbstickDownRight,
        keyboard,
      ),
      '62',
    );
    expect(
      defaultInputGlyphs.glyphName(
        GamepadInputType.rightThumbstickUpDown,
        keyboard,
      ),
      '82',
    );
  });

  test('maps hardware IDs and keyboard fallback', () {
    expect(
      InputDeviceProfile.fromHardwareIds(1118, 702).type,
      GamepadDevice.xbox360,
    );
    expect(
      InputDeviceProfile.fromHardwareIds(1356, 3302).type,
      GamepadDevice.ps5,
    );
    expect(
      InputDeviceProfile.fromHardwareIds(10462, 1).type,
      GamepadDevice.steamG1,
    );
    expect(
      InputDeviceProfile.fromHardwareIds(null, null).type,
      GamepadDevice.keyboard,
    );
    expect(
      InputDeviceProfile.fromHardwareIds(9999, 1).type,
      GamepadDevice.xboxOne,
    );
    expect(InputDeviceProfile.fromHardwareIds(9999, 1).isRecognized, isFalse);
  });

  test('maps Steam-G1 inputs to available Steam-G1 glyphs', () {
    const steamG1 = InputDeviceProfile(GamepadDevice.steamG1);

    expect(
      GamepadGlyph.assetPathFor(input: GamepadInputType.south, device: steamG1),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-A.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftShoulder,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-LB.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.dPadUpLeft,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-DPadUpLeft.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.dPadUpDown,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-DPadUpDown.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.dPadLeftRight,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-DPadLeftRight.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.dPadDownRight,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-DPadDownRight.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.dPadDownLeft,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-DPadDownLeft.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.dPadUpRight,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-DPadUpRight.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftRightShoulder,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-LeftRightShoulder.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftRightTrigger,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-LeftRightTrigger.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.rightThumbstick,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-Trackpad.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.rightThumbstickClockwise,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-TrackpadClockwise.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.rightThumbstickCounterclockwise,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-TrackpadCounterClockwise.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.rightThumbstickUpLeft,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-TrackpadUpLeft.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.rightThumbstickUpRight,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-TrackpadUpRight.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.rightThumbstickDownLeft,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-TrackpadDownLeft.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.rightThumbstickDownRight,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-TrackpadDownRight.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.rightThumbstickUpDown,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-TrackpadUpDown.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.rightThumbstickLeftRight,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-TrackpadLeftRight.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.homeButton,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-Steam Button.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftThumbstick,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-LeftThumbstick.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftThumbstickClockwise,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-LeftThumbstickRotationClockwise.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftThumbstickCounterclockwise,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-LeftThumbstickRotationCounterclockwise.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftThumbstickUp,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-LeftThumbstickUp.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftThumbstickDown,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-LeftThumbstickDown.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftThumbstickLeft,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-LeftThumbstickLeft.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftThumbstickRight,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-LeftThumbstickRight.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftThumbstickUpLeft,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-LeftThumbstickUpLeft.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftThumbstickDownRight,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-LeftThumbstickDownRight.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftThumbstickDownLeft,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-LeftThumbstickLeftDown.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftThumbstickUpRight,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-LeftThumbstickUpRight.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftThumbstickLeftRight,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-LeftThumbstickLeftRight.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftThumbstickUpDown,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-LeftThumbstickUpDown.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftThumbstickButton,
        device: steamG1,
      ),
      'assets/input_prompt/Steam (G1)/default/Steam-G1-LeftThumbstickClick.svg',
    );
  });

  test('tracker publishes the latest device profile', () {
    final tracker = InputDeviceTracker();
    expect(tracker.value.type, GamepadDevice.keyboard);

    tracker.updateHardwareIds(1118, 721);
    expect(tracker.value.type, GamepadDevice.xboxOne);

    tracker.updateHardwareIds(1356, 1476);
    expect(tracker.value.type, GamepadDevice.ps4);
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
    expect(tracker.value.type, GamepadDevice.ps4);
    tracker.dispose();
  });

  test('reverses composite axes and supports keyboard overrides', () {
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftThumbstickLeftRight,
        device: const InputDeviceProfile.keyboard(),
        reverseAxes: true,
      ),
      'assets/input_prompt/Keyboard/default/WS.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.south,
        device: const InputDeviceProfile.keyboard(),
        mappedKeyboardKey: 'Space',
      ),
      'assets/input_prompt/Keyboard/default/Space.svg',
    );
  });

  test('resolves named style folders', () {
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.south,
        device: const InputDeviceProfile.keyboard(),
        style: 'MonochromeLight',
      ),
      'assets/input_prompt/Keyboard/MonochromeLight/Space.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.south,
        device: const InputDeviceProfile.keyboard(),
        style: 'MonochromeDark',
      ),
      'assets/input_prompt/Keyboard/MonochromeDark/Space.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.south,
        device: const InputDeviceProfile(GamepadDevice.ps5),
        style: 'MonochromeDark',
      ),
      'assets/input_prompt/PS5/MonochromeDark/PS5-Cross.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.homeButton,
        device: const InputDeviceProfile(GamepadDevice.arcade),
        style: 'blue',
      ),
      'assets/input_prompt/Arcade/blue/Home.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.homeButton,
        device: const InputDeviceProfile(GamepadDevice.arcade),
        style: 'green',
      ),
      'assets/input_prompt/Arcade/green/Home.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.homeButton,
        device: const InputDeviceProfile(GamepadDevice.arcade),
        style: 'yellow',
      ),
      'assets/input_prompt/Arcade/yellow/Home.svg',
    );
  });

  test('tries the default style after a missing requested style', () {
    expect(
      GamepadGlyph.assetPathsFor(
        input: GamepadInputType.south,
        device: const InputDeviceProfile(GamepadDevice.ps5),
        style: 'NotAStyle',
      ),
      <String>[
        'assets/input_prompt/PS5/NotAStyle/PS5-Cross.svg',
        'assets/input_prompt/PS5/default/PS5-Cross.svg',
      ],
    );
  });

  test('allows keyboard mappings to be customized in one table', () {
    final customGlyphs = defaultInputGlyphs.withKeyboardOverrides({
      GamepadInputType.south: 'Z',
      GamepadInputType.east: 'Escape',
    });

    expect(
      customGlyphs.glyphName(GamepadInputType.south, GamepadDevice.keyboard),
      'Z',
    );
    expect(
      customGlyphs.glyphName(GamepadInputType.south, GamepadDevice.xboxOne),
      'A',
    );
    expect(
      defaultInputGlyphs.glyphName(
        GamepadInputType.south,
        GamepadDevice.keyboard,
      ),
      'Space',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.south,
        device: const InputDeviceProfile.keyboard(),
        glyphs: customGlyphs,
      ),
      'assets/input_prompt/Keyboard/default/Z.svg',
    );
  });

  testWidgets('renders an empty box for a missing custom glyph', (
    tester,
  ) async {
    final customGlyphs = defaultInputGlyphs.withKeyboardOverrides({
      GamepadInputType.south: 'DoesNotExist',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: GamepadGlyph(
          input: GamepadInputType.south,
          forceDeviceType: GamepadDevice.keyboard,
          glyphs: customGlyphs,
          width: 48,
          height: 48,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GamepadGlyph), findsOneWidget);
  });

  testWidgets('renders the default keyboard pair glyphs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            GamepadGlyph(
              input: GamepadInputType.dPadUpDown,
              forceDeviceType: GamepadDevice.keyboard,
            ),
            GamepadGlyph(
              input: GamepadInputType.leftThumbstickUpDown,
              forceDeviceType: GamepadDevice.keyboard,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsNWidgets(2));
  });

  testWidgets('renders the default keyboard F1 glyph', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GamepadGlyph(
          input: GamepadInputType.homeButton,
          forceDeviceType: GamepadDevice.keyboard,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('silently falls back to a hardware default style', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GamepadGlyph(
          input: GamepadInputType.south,
          forceDeviceType: GamepadDevice.ps5,
          style: 'NotAStyle',
          width: 48,
          height: 48,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GamepadGlyph), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('uses a per-hardware style in preference to the shared style', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GamepadGlyph(
          input: GamepadInputType.homeButton,
          forceDeviceType: GamepadDevice.keyboard,
          style: 'NotAStyle',
          deviceStyles: <GamepadDevice, String>{
            GamepadDevice.keyboard: 'Light',
          },
          width: 48,
          height: 48,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('loads an alternate style when it is available', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GamepadGlyph(
          input: GamepadInputType.south,
          forceDeviceType: GamepadDevice.ps5,
          style: 'MonochromeDark',
          width: 48,
          height: 48,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsOneWidget);
  });

  test('uses available Nintendo Switch glyph names', () {
    const switchDevice = InputDeviceProfile(GamepadDevice.switchJoyCon);

    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.view,
        device: switchDevice,
      ),
      'assets/input_prompt/Switch Joy-Con/default/Switch-Minus.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.menu,
        device: switchDevice,
      ),
      'assets/input_prompt/Switch Joy-Con/default/Switch-Plus.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.rightThumbstick,
        device: switchDevice,
      ),
      'assets/input_prompt/Switch Joy-Con/default/Switch-RightThumbStick.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftThumbstickButton,
        device: switchDevice,
      ),
      'assets/input_prompt/Switch Joy-Con/default/Switch-LeftThumbStickButton.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.rightThumbstickButton,
        device: switchDevice,
      ),
      'assets/input_prompt/Switch Joy-Con/default/Switch-RightThumbStickButton.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.dPadUpLeft,
        device: switchDevice,
      ),
      'assets/input_prompt/Switch Joy-Con/default/Switch-DPadUpLeft.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.dPadDownRight,
        device: switchDevice,
      ),
      'assets/input_prompt/Switch Joy-Con/default/Switch-DPadDownRight.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.dPadUpDown,
        device: switchDevice,
      ),
      'assets/input_prompt/Switch Joy-Con/default/Switch-DPadUpDown.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.dPadLeftRight,
        device: switchDevice,
      ),
      'assets/input_prompt/Switch Joy-Con/default/Switch-DPadLeftRight.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.dPad,
        device: switchDevice,
      ),
      'assets/input_prompt/Switch Joy-Con/default/Switch-DPad.svg',
    );
  });

  test('uses available Home button glyph names', () {
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.homeButton,
        device: const InputDeviceProfile(GamepadDevice.xbox360),
      ),
      'assets/input_prompt/Xbox 360/default/Xbox 360-Home.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.homeButton,
        device: const InputDeviceProfile(GamepadDevice.xboxOne),
      ),
      'assets/input_prompt/Xbox One/default/Xbox One-Home.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.homeButton,
        device: const InputDeviceProfile(GamepadDevice.ps5),
      ),
      'assets/input_prompt/PS5/default/PS5-Home.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.homeButton,
        device: const InputDeviceProfile(GamepadDevice.wii),
      ),
      'assets/input_prompt/Wii/default/Wii-Home.svg',
    );
  });

  test('resolves keyboard diagonal glyph assets', () {
    const keyboard = InputDeviceProfile.keyboard();

    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.dPadUpLeft,
        device: keyboard,
      ),
      'assets/input_prompt/Keyboard/default/UpLeft.svg',
    );
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftThumbstickDownRight,
        device: keyboard,
      ),
      'assets/input_prompt/Keyboard/default/SD.svg',
    );
  });

  test('loads the derived PS3 diagonal thumbstick glyph', () {
    expect(
      GamepadGlyph.assetPathFor(
        input: GamepadInputType.leftThumbstickUpLeft,
        device: const InputDeviceProfile(GamepadDevice.ps3),
      ),
      'assets/input_prompt/PS3/default/PS3-LeftThumbstickUpLeft.svg',
    );
  });
}
