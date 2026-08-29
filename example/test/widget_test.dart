import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:gamepad_glyphs_example/main.dart';

void main() {
  testWidgets('shows the GamepadGlyph example', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const GamepadGlyphExampleApp());
    expect(find.text('Click to Simulate Input Device'), findsOneWidget);
    expect(find.text('Select Item'), findsOneWidget);
    expect(find.text('Xbox 360'), findsOneWidget);
    expect(find.text('DualSense (PS5)'), findsOneWidget);
    expect(find.text('Show Map'), findsOneWidget);

    expect(find.byType(ExcludeFocus), findsAtLeastNWidgets(2));

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
