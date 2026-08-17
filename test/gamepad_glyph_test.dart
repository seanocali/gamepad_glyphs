import 'package:flutter_test/flutter_test.dart';
import 'package:gamepad_glyphs/gamepad_glyphs.dart';

void main() {
  test('resolves semantic filenames in extension preference order', () {
    const device = 'Xbox One';

    expect(GamepadGlyph.assetPathsFor(input: 'south', device: device), <String>[
      'assets/input_prompt/Xbox One/south.svg',
      'assets/input_prompt/Xbox One/south.png',
      'assets/input_prompt/Xbox One/south.webp',
      'assets/input_prompt/Xbox One/south.gif',
      'assets/input_prompt/Xbox One/south.apng',
      'assets/input_prompt/Xbox One/south.jpg',
      'assets/input_prompt/Xbox One/south.jpeg',
    ]);
  });

  test('reverses composite axes by filename', () {
    const device = 'Keyboard';

    expect(
      GamepadGlyph.assetPathFor(
        input: 'dPadUpDown',
        device: device,
        reverseAxes: true,
      ),
      'assets/input_prompt/Keyboard/d_pad_left_right.svg',
    );
  });
}
