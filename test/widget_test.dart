import 'package:flutter_test/flutter_test.dart';
import 'package:student_management/main.dart';

void main() {
  testWidgets('dashboard mounts without a setState callback error', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Peng Maleap'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Notepad'), findsOneWidget);
    expect(find.text('Student List'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
