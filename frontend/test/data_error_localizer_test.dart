import 'package:flutter_test/flutter_test.dart';
import 'package:football_tactics_app/core/data_error_localizer.dart';

void main() {
  test('explains unavailable scorer statistics in both app languages', () {
    const error = 'Top-scorer data is not included in the current plan.';

    expect(
      localizedDataError(error, isArabic: true, fallback: 'fallback'),
      contains('خطة مزوّد البيانات'),
    );
    expect(
      localizedDataError(error, isArabic: false, fallback: 'fallback'),
      contains('does not include top-scorer'),
    );
  });

  test('localizes rate-limit errors without exposing provider internals', () {
    final message = localizedDataError(
      Exception('provider returned HTTP 429'),
      isArabic: true,
      fallback: 'fallback',
    );

    expect(message, contains('حد الطلبات'));
    expect(message, isNot(contains('429')));
  });
}
