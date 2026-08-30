import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:gamepad_glyphs_example/main.dart';

void main() {
  testWidgets('switches between gamepad and TV remote simulations', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const GamepadGlyphExampleApp());
    expect(find.text('Click to Simulate Input Device'), findsOneWidget);
    expect(find.text('Select Item'), findsOneWidget);
    expect(find.text('Xbox 360'), findsOneWidget);
    expect(find.text('DualSense (PS5)'), findsOneWidget);
    expect(find.text('Show Map'), findsOneWidget);
    expect(find.text('Gamepad'), findsOneWidget);
    expect(find.text('TV Remote'), findsOneWidget);

    expect(find.byType(ExcludeFocus), findsAtLeastNWidgets(2));

    await tester.tap(find.text('TV Remote'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ElevatedButton, 'Apple TV'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Google TV'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Fire TV'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Xbox One'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Keyboard'), findsOneWidget);
    for (final label in [
      'Left',
      'OK',
      'Back',
      'Right',
      'Rewind',
      'Fast Forward',
      'Home',
      'Voice',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Gamepad'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show Map'));
    await tester.pumpAndSettle();
    expect(find.text('Input Glyph Map'), findsOneWidget);
    expect(find.text('Arcade'), findsOneWidget);

    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scrollView.scrollDirection, Axis.vertical);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is FittedBox && widget.fit == BoxFit.fitWidth,
      ),
      findsNWidgets(2),
    );
  });
}
