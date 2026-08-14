import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:gamepad_glyphs_example/main.dart';

void main() {
  testWidgets('shows the GamepadGlyph example', (WidgetTester tester) async {
    await tester.pumpWidget(const GamepadGlyphExampleApp());
    expect(
      find.textContaining('Alternate between keyboard input'),
      findsOneWidget,
    );
    expect(find.text('Select Item'), findsOneWidget);
    expect(find.text('Simulate Xbox 360 Gamepad Input'), findsOneWidget);
    expect(find.text('Simulate PlayStation 5 DualSense Input'), findsOneWidget);
    expect(find.text('Use Monochrome Icons'), findsOneWidget);
    expect(find.text('Show Map'), findsOneWidget);

    expect(find.byType(ExcludeFocus), findsNWidgets(2));

    await tester.tap(find.text('Show Map'));
    await tester.pumpAndSettle();
    expect(find.text('Input Glyph Map'), findsOneWidget);

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
