import 'package:flutter_test/flutter_test.dart';
import 'package:cash_flow_app/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const CashFlowApp());

    // Verify the login screen loads
    expect(find.text('Buku Kas'), findsAny);
  });
}
