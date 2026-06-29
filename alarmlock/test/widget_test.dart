import 'package:flutter_test/flutter_test.dart';
import 'package:alarmlock/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const PushAlarmApp());
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
