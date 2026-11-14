import 'package:flutter_test/flutter_test.dart';
import 'package:football_tactics_app/core/data_source_label.dart';

void main() {
  test('source badges are localized and unknown sources stay hidden', () {
    expect(
      dataSourceLabel('football-data', isArabic: true),
      'المصدر: football-data.org',
    );
    expect(
      dataSourceLabel('highlightly', isArabic: false),
      'Source: Highlightly',
    );
    expect(dataSourceLabel(null, isArabic: true), isNull);
  });
}
