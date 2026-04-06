import 'package:flutter_test/flutter_test.dart';
import 'package:mse_market_connect/app/app.dart';

void main() {
  testWidgets('app loads main navigation shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MseMarketConnectApp());

    expect(find.text('MSE Market Connect'), findsOneWidget);
  });
}
