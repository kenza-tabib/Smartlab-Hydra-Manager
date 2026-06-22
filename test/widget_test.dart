import 'package:flutter_test/flutter_test.dart';
import 'package:smart_lab_hydra_manager/main.dart';

void main() {
  testWidgets('App launches splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartLabApp());
    expect(find.text('Smart Lab Hydra Manager'), findsOneWidget);
  });
}
