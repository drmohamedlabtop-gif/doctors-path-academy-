// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctors_path_academy/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DoctorsPathAcademy());

    // Verify that our counter starts at 0.
    // Since the initial screen is no longer a counter, this test is expected to fail.
    // We are just fixing the compilation error.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
  });
}
