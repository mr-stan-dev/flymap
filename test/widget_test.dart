// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:flymap/main.dart';
import 'package:flymap/di/di_module.dart';
import 'package:flymap/data/local/app_database.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    // Register dependencies used by the app
    DiModule().register();
    await GetIt.I<AppDatabase>().initialize();

    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
