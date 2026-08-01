import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aari_ai_designer/app.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AariApp()));
    await tester.pump();

    expect(find.text('AARI AI DESIGNER'), findsOneWidget);
  });
}
