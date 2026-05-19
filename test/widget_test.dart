import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const NotebookApp());
    await tester.pumpAndSettle();
    expect(find.text('My Notes'), findsOneWidget);
  });
}