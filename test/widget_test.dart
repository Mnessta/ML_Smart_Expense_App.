import 'package:flutter_test/flutter_test.dart';
import 'package:ml_smart_expense_track/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app builds without errors
    expect(find.byType(MyApp), findsOneWidget);
  });
}
