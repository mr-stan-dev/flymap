import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/home/tabs/home/home_tab.dart';
import 'package:flymap/ui/screens/home/tabs/library/library_tab.dart';
import 'package:flymap/ui/screens/settings/settings_screen.dart';

enum HomeRootTab { flights, library, settings }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialTab = HomeRootTab.flights});

  final HomeRootTab initialTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _tabIndex;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab.index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titleForIndex(context, _tabIndex))),
      body: IndexedStack(
        index: _tabIndex,
        children: const [HomeTab(), LibraryTab(), SettingsContent()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (index) => setState(() => _tabIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.flight_outlined),
            activeIcon: const Icon(Icons.flight),
            label: context.t.home.tabFlights,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.school_outlined),
            activeIcon: const Icon(Icons.school),
            label: context.t.home.tabLibrary,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: context.t.settings.title,
          ),
        ],
      ),
    );
  }

  String _titleForIndex(BuildContext context, int index) {
    switch (HomeRootTab.values[index]) {
      case HomeRootTab.flights:
        return context.t.home.tabFlights;
      case HomeRootTab.library:
        return context.t.home.tabLibrary;
      case HomeRootTab.settings:
        return context.t.settings.title;
    }
  }
}
