import 'package:flutter_test/flutter_test.dart';
import 'package:speaking_clock/main.dart';

void main() {
  testWidgets('shows the Today experience', (tester) async {
    await tester.pumpWidget(const SpeakingClockApp());
    await tester.pumpAndSettle();

    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('Drink water'), findsOneWidget);
    expect(find.text('Add reminder'), findsOneWidget);
  });

  testWidgets('opens the editor from add reminder and routine presets', (tester) async {
    await tester.pumpWidget(const SpeakingClockApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add reminder'));
    await tester.pumpAndSettle();
    expect(find.text('New reminder'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eye break'));
    await tester.pumpAndSettle();
    expect(find.text('New reminder'), findsOneWidget);
    expect(find.text('Break'), findsOneWidget);
  });
}
