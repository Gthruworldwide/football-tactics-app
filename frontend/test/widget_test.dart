import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:football_tactics_app/main.dart';

void main() {
  testWidgets('football tactics app shows its navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FootballTacticsApp());

    expect(find.byType(NavigationBar), findsOneWidget);
    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.destinations, hasLength(3));
  });
}
