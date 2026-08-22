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

  testWidgets('PremiumButton uses accessible gold in both themes', (
    tester,
  ) async {
    for (final theme in <ThemeData>[AppTheme.lightTheme, AppTheme.darkTheme]) {
      await pumpWithTheme(
        tester,
        theme: theme,
        child: const PremiumButton(label: 'Upgrade', onPressed: _noop),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(
        button.style?.backgroundColor?.resolve(<WidgetState>{}),
        DsPremiumColors.goldFill,
      );
      expect(
        button.style?.foregroundColor?.resolve(<WidgetState>{}),
        DsPremiumColors.onGold,
      );
      expect(
        tester.widget<Text>(find.text('Upgrade')).style?.color,
        DsPremiumColors.onGold,
      );
    }
  });

  testWidgets('compact action buttons keep content visible', (tester) async {
    await pumpWithTheme(
      tester,
      theme: AppTheme.darkTheme,
      child: SizedBox(
        width: 220,
        child: const SecondaryButton(
          label: 'Manage subscription',
          trailingIcon: Icons.open_in_new_rounded,
          compact: true,
          onPressed: _noop,
        ),
      ),
    );

    expect(tester.getSize(find.byType(OutlinedButton)).height, 44);
    expect(find.text('Manage subscription'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpWithTheme(
      tester,
      theme: AppTheme.darkTheme,
      child: SizedBox(
        width: 220,
        child: const TertiaryButton(
          label: 'Restore purchases',
          leadingIcon: Icons.restore_rounded,
          compact: true,
          onPressed: _noop,
        ),
      ),
    );

    expect(tester.getSize(find.byType(TextButton)).height, 44);
    expect(find.text('Restore purchases'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
