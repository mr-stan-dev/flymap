import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/home/tabs/home/home_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.home.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => AppRouter.goToAbout(context),
            tooltip: context.t.home.aboutTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              AppRouter.goToSettings(context);
            },
            tooltip: context.t.home.settingsTooltip,
          ),
        ],
      ),
      body: const HomeTab(),
    );
  }
}
