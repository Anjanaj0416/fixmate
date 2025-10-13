// test/widget_test.dart
// FIXED VERSION - Now uses FixMateApp instead of MyApp
// This is a basic Flutter widget test template

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixmate/main.dart';

void main() {
  testWidgets('FixMate app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(FixMateApp());

    // Verify that the app launches
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
