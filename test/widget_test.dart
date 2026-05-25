import 'package:flutter_test/flutter_test.dart';
import 'package:serviorl/main.dart';

void main() {
  testWidgets('ServioRL smoke test', (WidgetTester tester) async {
    // Build app and trigger a frame.
    await tester.pumpWidget(const ServioRLApp());
    // Basic smoke test — app renders without crashing
    expect(find.byType(ServioRLApp), findsOneWidget);
  });
}
