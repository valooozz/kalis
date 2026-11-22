// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kalis/main.dart';
import 'package:kalis/core/router/app_router.dart';

void main() {
  testWidgets('KalisApp builds inside a ProviderScope', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('Kalis test route')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [routerProvider.overrideWithValue(router)],
        child: const KalisApp(),
      ),
    );

    expect(find.text('Kalis test route'), findsOneWidget);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).title, 'Kalis');
  });
}
