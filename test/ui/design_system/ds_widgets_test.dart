import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/theme/app_theme.dart';

void main() {
  Future<void> pumpWithTheme(
    WidgetTester tester, {
    required Widget child,
    required ThemeData theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('PrimaryButton supports loading and disabled states', (
    tester,
  ) async {
    await pumpWithTheme(
      tester,
      theme: AppTheme.darkTheme,
      child: const PrimaryButton(label: 'Continue', onPressed: null),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await pumpWithTheme(
      tester,
      theme: AppTheme.darkTheme,
      child: const PrimaryButton(
        label: 'Continue',
        onPressed: null,
        isLoading: true,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('StatusChip renders tone label', (tester) async {
    await pumpWithTheme(
      tester,
      theme: AppTheme.lightTheme,
      child: const StatusChip(
        label: 'Saved offline',
        tone: StatusChipTone.success,
      ),
    );

    expect(find.text('Saved offline'), findsOneWidget);
  });

  testWidgets('SearchInputField handles multiple suffix actions', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'LHR');
    addTearDown(controller.dispose);

    await pumpWithTheme(
      tester,
      theme: AppTheme.lightTheme,
      child: SizedBox(
        width: 240,
        child: SearchInputField(
          controller: controller,
          hintText: 'Search airport',
          suffixActions: [
            IconButton(onPressed: _noop, icon: const Icon(Icons.star)),
            IconButton(onPressed: _noop, icon: const Icon(Icons.close)),
          ],
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(SearchInputField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProgressStateView renders progress and secondary line', (
    tester,
  ) async {
    await pumpWithTheme(
      tester,
      theme: AppTheme.darkTheme,
      child: const ProgressStateView(
        title: 'Downloading offline map...',
        progress: 0.42,
        secondaryLine: 'Downloaded: 12.4 MB',
      ),
    );

    expect(find.text('Downloading offline map...'), findsOneWidget);
    expect(find.text('Downloaded: 12.4 MB'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('PrimaryButton renders in light and dark themes', (tester) async {
    await pumpWithTheme(
      tester,
      theme: AppTheme.lightTheme,
      child: const PrimaryButton(label: 'Download', onPressed: _noop),
    );
    expect(find.text('Download'), findsOneWidget);

    await pumpWithTheme(
      tester,
      theme: AppTheme.darkTheme,
      child: const PrimaryButton(label: 'Download', onPressed: _noop),
    );
    expect(find.text('Download'), findsOneWidget);
  });
}

void _noop() {}
