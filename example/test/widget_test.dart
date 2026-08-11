import 'package:flutter_test/flutter_test.dart';

import 'package:gamepad_glyphs_example/main.dart';

void main() {
  testWidgets('shows the InputPrompt example', (WidgetTester tester) async {
    await tester.pumpWidget(const InputPromptExampleApp());
    expect(find.text('InputPrompt example'), findsOneWidget);
    expect(find.text('Select Item'), findsOneWidget);
  });
}
