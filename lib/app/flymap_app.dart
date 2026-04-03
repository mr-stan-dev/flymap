import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/settings/viewmodel/settings_cubit.dart';
import 'package:flymap/ui/screens/settings/viewmodel/settings_state.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/theme/app_theme.dart';
import 'package:get_it/get_it.dart';

import '../repository/subscription_repository.dart';
import '../router/app_router.dart';

class FlymapApp extends StatefulWidget {
  const FlymapApp({required this.showOnboarding, super.key});

  final bool showOnboarding;

  @override
  State<FlymapApp> createState() => _FlymapAppState();
}

class _FlymapAppState extends State<FlymapApp> {
  late final router = AppRouter.createRouter(
    showOnboarding: widget.showOnboarding,
  );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsCubit()..load()),
        BlocProvider(
          create: (_) => SubscriptionCubit(
            repository: GetIt.I.get<SubscriptionRepository>(),
            analytics: GetIt.I.get<AppAnalytics>(),
          )..initialize(),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return MaterialApp.router(
            title: t.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            debugShowCheckedModeBanner: false,
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
