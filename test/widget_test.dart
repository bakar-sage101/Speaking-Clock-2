import 'package:flutter_test/flutter_test.dart';
import 'package:speaking_clock/main.dart';

void main() {
  testWidgets('shows the Today experience', (tester) async {
    await tester.pumpWidget(const SpeakingClockApp());

    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('Drink water'), findsOneWidget);
    expect(find.text('Add reminder'), findsOneWidget);
  });
}
