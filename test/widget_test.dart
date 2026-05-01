import 'package:flutter_test/flutter_test.dart';
import 'package:dino_manager/main.dart';

void main() {
  testWidgets('App builds without crash', (WidgetTester tester) async {
    await tester.pumpWidget(const DinoManagerApp());
    expect(find.byType(DinoManagerApp), findsOneWidget);
  });
}
