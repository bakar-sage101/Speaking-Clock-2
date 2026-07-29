import 'package:flutter_test/flutter_test.dart';
import 'package:speaking_clock/main.dart';

void main() {
  testWidgets('shows the Today experience', (tester) async {
    await tester.pumpWidget(const SpeakingClockApp());
    await tester.pumpAndSettle();

    expect(find.byType(TodayDial), findsOneWidget);
    expect(find.text('Drink water'), findsOneWidget);
  });

  testWidgets('opens and closes the reminder editor', (tester) async {
    await tester.pumpWidget(const SpeakingClockApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TodayDial));
    await tester.pumpAndSettle();
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('New reminder'), findsWidgets);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel'), findsNothing);
  });
}
