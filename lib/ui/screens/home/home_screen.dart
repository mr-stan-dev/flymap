import 'package:flymap/ui/screens/home/tabs/home/home_tab.dart';
import 'package:flutter/material.dart';
import 'package:flymap/ui/screens/settings/settings_screen.dart';
import 'package:flymap/router/app_router.dart';

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
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => AppRouter.goToAbout(context),
            tooltip: 'About',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              AppRouter.goToSettings(context);
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: const HomeTab(),
    );
  }
}
