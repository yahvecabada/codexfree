import 'package:appyahve/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppYahve shows the math adventure home screen', (tester) async {
    await tester.pumpWidget(const AppYahve());

    expect(find.text('AppYahve'), findsOneWidget);
    expect(find.text('Sumar'), findsOneWidget);
    expect(find.text('Restar'), findsOneWidget);
    expect(find.text('Multiplicar'), findsOneWidget);
    expect(find.textContaining('Toca la respuesta correcta'), findsOneWidget);
  });
}
