import 'package:flutter_test/flutter_test.dart';
import 'package:hygiene_coach/main.dart';

void main() {
  testWidgets('App launches and shows onboarding or home', (WidgetTester tester) async {
    await tester.pumpWidget(const HygieneCoachApp());
    await tester.pump();
    expect(find.byType(HygieneCoachApp), findsOneWidget);
  });
}
