import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:football_tactics_app/main.dart';

void main() {
  testWidgets('App builds with bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const FootballTacticsApp());

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('الترتيب'), findsOneWidget);
  });
}
