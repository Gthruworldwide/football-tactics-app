import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasl_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('starts as a clean general-purpose Wasl app', (tester) async {
    await tester.pumpWidget(const WaslApp());
    await tester.pumpAndSettle();

    expect(find.text('وصل'), findsOneWidget);
    expect(
      find.text('ابدأ مساحة معرفتك بإضافة أول كيان ومصدره.'),
      findsOneWidget,
    );
    expect(find.textContaining('Football'), findsNothing);
  });
}
