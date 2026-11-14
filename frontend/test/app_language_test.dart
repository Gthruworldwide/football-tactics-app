import 'package:flutter_test/flutter_test.dart';
import 'package:football_tactics_app/core/services/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('language selection is saved and restored', () async {
    SharedPreferences.setMockInitialValues({});

    await AppLanguage.instance.setLanguage('en');
    expect(AppLanguage.instance.locale.languageCode, 'en');
    expect(
      (await SharedPreferences.getInstance()).getString('app_language'),
      'en',
    );

    await AppLanguage.instance.setLanguage('ar');
    expect(AppLanguage.instance.locale.languageCode, 'ar');
  });
}
