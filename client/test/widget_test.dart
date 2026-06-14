import 'package:flutter_test/flutter_test.dart';
import 'package:wallstreet/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const WallstreetApp());
    await tester.pump();
    expect(find.text('Wallstreet'), findsOneWidget);
  });
}
