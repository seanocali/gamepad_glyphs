import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gamepad_glyphs/gamepad_glyphs.dart';

void main() {
  test('bundles generated default Keyboard glyphs', () async {
    for (final name in ['0.svg', 'P.svg']) {
      final data = await rootBundle.load(
        'packages/gamepad_glyphs/assets/input_prompt/Keyboard/$name',
      );
      expect(data.lengthInBytes, greaterThan(0));
    }
  });

  test('Switch Joy-Con LR glyph has no trackpad-swipe artwork', () {
    final source = File(
      'assets/input_prompt/Switch Joy-Con/lr.svg',
    ).readAsStringSync();

    expect(source, isNot(contains('M380.21,262.55')));
  });

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
        input: 'dpUpDown',
        device: device,
        reverseAxes: true,
      ),
      'assets/input_prompt/Keyboard/dp_left_right.svg',
    );
  });

  testWidgets('resolves a generic input through a folder map', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GamepadGlyph(input: 'lt', device: 'Switch Joy-Con'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('loads the Switch Pro face-button glyphs', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GamepadGlyph(input: 'Y', device: 'Switch Pro'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('loads the Steam G2 face-button glyphs', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GamepadGlyph(input: 'Y', device: 'Steam (G2)'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('maps Keyboard generic inputs to actual key assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Row(
          children: [
            GamepadGlyph(input: 'X', device: 'Keyboard'),
            GamepadGlyph(input: 'lsCw', device: 'Keyboard'),
            GamepadGlyph(input: 'rt', device: 'Keyboard'),
            GamepadGlyph(input: 'home', device: 'Keyboard'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsNWidgets(4));
  });

  testWidgets('resolves every main-screen prompt for each simulated device', (
    tester,
  ) async {
    const devices = <String>[
      'Xbox 360',
      'Xbox One',
      'Xbox Series X-S',
      'PS3',
      'PS4',
      'PS5',
      'Switch Joy-Con',
      'Switch Pro',
      'Steam (G1)',
      'Steam (G2)',
      'Arcade',
      'Keyboard',
    ];
    const inputs = <String>[
      'ls_up_down',
      'lb_rb',
      'Y',
      'X',
      'B',
      'A',
      'rs_left_right',
      'rs_cw',
      'dp',
      'lt_rt',
      'view',
      'menu',
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Wrap(
          children: [
            for (final device in devices)
              for (final input in inputs)
                GamepadGlyph(input: input, device: device),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byType(SvgPicture),
      findsNWidgets(devices.length * inputs.length),
    );
  });

  test('style folders match their parent filenames and inherit its map', () {
    const styleParents = <String, List<String>>{
      'Arcade': ['blue', 'green', 'yellow'],
      'Keyboard': ['Light', 'MonochromeDark', 'MonochromeLight'],
      'PS5': ['MonochromeDark'],
      'Xbox Series X-S': ['MonochromeDark'],
    };

    for (final entry in styleParents.entries) {
      final root = Directory('assets/input_prompt/${entry.key}');
      final defaultNames = _svgNames(root);
      for (final style in entry.value) {
        final styleDirectory = Directory(
          '${root.path}${Platform.pathSeparator}$style',
        );
        expect(
          _svgNames(styleDirectory),
          defaultNames,
          reason: '${entry.key}/$style',
        );
        expect(
          File(
            '${styleDirectory.path}${Platform.pathSeparator}map.conf',
          ).existsSync(),
          isFalse,
          reason: '${entry.key}/$style',
        );
      }
    }
  });

  testWidgets('styles inherit their parent map', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Wrap(
          children: [
            for (final style in [
              'Light',
              'MonochromeDark',
              'MonochromeLight',
            ]) ...[
              GamepadGlyph(input: 'Y', device: 'Keyboard', style: style),
              GamepadGlyph(input: 'lsCw', device: 'Keyboard', style: style),
              GamepadGlyph(input: 'home', device: 'Keyboard', style: style),
            ],
            GamepadGlyph(input: 'A', device: 'Arcade', style: 'blue'),
            GamepadGlyph(input: 'Y', device: 'PS5', style: 'MonochromeDark'),
            GamepadGlyph(
              input: 'Y',
              device: 'Xbox Series X-S',
              style: 'MonochromeDark',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsNWidgets(12));
  });

  testWidgets('loads generated Keyboard monochrome glyph variants', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Row(
          children: [
            GamepadGlyph(
              input: 'bracketRight',
              device: 'Keyboard',
              style: 'MonochromeDark',
            ),
            GamepadGlyph(
              input: '84',
              device: 'Keyboard',
              style: 'MonochromeDark',
            ),
            GamepadGlyph(
              input: '1',
              device: 'Keyboard',
              style: 'MonochromeLight',
            ),
            GamepadGlyph(
              input: '84',
              device: 'Keyboard',
              style: 'MonochromeLight',
            ),
            GamepadGlyph(input: '0', device: 'Keyboard'),
            GamepadGlyph(input: 'P.svg', device: 'Keyboard'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsNWidgets(6));
  });
}

Set<String> _svgNames(Directory directory) => directory
    .listSync()
    .whereType<File>()
    .map((file) => file.uri.pathSegments.last)
    .where((name) => name.endsWith('.svg'))
    .toSet();
