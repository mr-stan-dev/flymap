import 'package:firebase_core/firebase_core.dart';
import 'package:flymap/cubit_state_observer.dart';
import 'package:flymap/data/local/app_database.dart';
import 'package:flymap/data/glyphs_service.dart';
import 'package:flymap/data/sprite_service.dart';
import 'package:flymap/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'di/di_module.dart';
import 'router/app_router.dart';
import 'ui/screens/settings/viewmodel/settings_cubit.dart';
import 'ui/screens/settings/viewmodel/settings_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Register dependencies
  DiModule().register();
  await GlyphsService().copyGlyphsToCacheDir();
  await SpriteService().copySpritesToCacheDir();

  // Initialize database
  await GetIt.I<AppDatabase>().initialize();

  Bloc.observer = CubitStateObserver.create();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final router = AppRouter.createRouter();
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit()..load(),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return MaterialApp.router(
            title: 'flymap',
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
