import 'package:flutter_test/flutter_test.dart';
import 'package:furqan/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
  });
}
