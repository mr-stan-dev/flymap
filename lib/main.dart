import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/cubit_state_observer.dart';
import 'package:flymap/data/glyphs_service.dart';
import 'package:flymap/data/local/app_database.dart';
import 'package:flymap/data/sprite_service.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/ui/theme/app_theme.dart';
import 'package:get_it/get_it.dart';

import 'di/di_module.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'ui/screens/settings/viewmodel/settings_cubit.dart';
import 'ui/screens/settings/viewmodel/settings_state.dart';
import 'ui/screens/subscription/viewmodel/subscription_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Register dependencies
  DiModule().register();
  await GlyphsService().copyGlyphsToCacheDir();
  await SpriteService().copySpritesToCacheDir();

  // Initialize database
  await GetIt.I<AppDatabase>().initialize();

  final hasSeenOnboarding = await GetIt.I<OnboardingRepository>()
      .hasSeenOnboarding();

  Bloc.observer = CubitStateObserver.create();
  runApp(MyApp(showOnboarding: !hasSeenOnboarding));
}

class MyApp extends StatefulWidget {
  const MyApp({required this.showOnboarding, super.key});

  final bool showOnboarding;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final router = AppRouter.createRouter(
    showOnboarding: widget.showOnboarding,
  );
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsCubit()..load()),
        BlocProvider(
          create: (_) =>
              SubscriptionCubit(repository: GetIt.I.get())..initialize(),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return MaterialApp.router(
            title: 'Flymap',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            debugShowCheckedModeBanner: false,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
