import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/rating/rate_prompt_policy_service.dart';
import 'package:flymap/rating/rate_review_launcher.dart';
import 'package:flymap/repository/feature_announcement_repository.dart';
import 'package:flymap/ui/screens/home/tabs/home/home_tab.dart';
import 'package:flymap/ui/screens/home/tabs/learn/learn_tab.dart';
import 'package:flymap/ui/screens/settings/settings_screen.dart';
import 'package:flymap/ui/widgets/rate_app_dialog.dart';
import 'package:get_it/get_it.dart';

enum HomeRootTab { flights, learn, settings }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialTab = HomeRootTab.flights});

  final HomeRootTab initialTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late int _tabIndex;
  bool _isRatePromptInFlight = false;
  bool _showLearnGeoQuizDot = false;
  bool _showLearnGeoQuizNewBadge = false;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab.index;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybePromptForRating());
      unawaited(_loadFeatureAnnouncements());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_maybePromptForRating());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titleForIndex(context, _tabIndex))),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          const HomeTab(),
          LearnTab(showGeoQuizNewBadge: _showLearnGeoQuizNewBadge),
          const SettingsContent(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.72),
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        selectedIconTheme: const IconThemeData(size: 26),
        unselectedIconTheme: const IconThemeData(size: 24),
        currentIndex: _tabIndex,
        onTap: (index) {
          final nextTab = HomeRootTab.values[index];
          setState(() {
            _tabIndex = index;
            if (nextTab == HomeRootTab.learn && _showLearnGeoQuizDot) {
              _showLearnGeoQuizDot = false;
              _showLearnGeoQuizNewBadge = true;
            }
          });
          if (nextTab == HomeRootTab.learn) {
            unawaited(_markGeoQuizAnnouncementSeen());
          }
          unawaited(_maybePromptForRating());
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.flight_outlined),
            activeIcon: const Icon(Icons.flight),
            label: context.t.home.tabFlights,
          ),
          BottomNavigationBarItem(
            icon: _NewFeatureNavIcon(
              icon: Icons.school_outlined,
              showBadge: _showLearnGeoQuizDot,
            ),
            activeIcon: _NewFeatureNavIcon(
              icon: Icons.school,
              showBadge: _showLearnGeoQuizDot,
            ),
            label: context.t.home.tabLearn,
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

  Future<void> _loadFeatureAnnouncements() async {
    if (!GetIt.I.isRegistered<FeatureAnnouncementRepository>()) return;
    final repository = GetIt.I.get<FeatureAnnouncementRepository>();
    final shouldShow = await repository.shouldShowForExistingUser(
      FeatureAnnouncement.geoQuizLearn,
    );
    if (!mounted) return;

    if (HomeRootTab.values[_tabIndex] == HomeRootTab.learn && shouldShow) {
      setState(() => _showLearnGeoQuizNewBadge = true);
      await repository.markSeen(FeatureAnnouncement.geoQuizLearn);
      return;
    }

    setState(() => _showLearnGeoQuizDot = shouldShow);
  }

  Future<void> _markGeoQuizAnnouncementSeen() async {
    if (!GetIt.I.isRegistered<FeatureAnnouncementRepository>()) return;
    await GetIt.I.get<FeatureAnnouncementRepository>().markSeen(
      FeatureAnnouncement.geoQuizLearn,
    );
  }

  String _titleForIndex(BuildContext context, int index) {
    switch (HomeRootTab.values[index]) {
      case HomeRootTab.flights:
        return context.t.home.tabFlights;
      case HomeRootTab.learn:
        return context.t.home.tabLearn;
      case HomeRootTab.settings:
        return context.t.settings.title;
    }
  }

  Future<void> _maybePromptForRating() async {
    if (!mounted || _isRatePromptInFlight) return;
    if (HomeRootTab.values[_tabIndex] != HomeRootTab.flights) return;

    _isRatePromptInFlight = true;
    final policy = GetIt.I.get<RatePromptPolicyService>();
    try {
      final shouldShow = await policy.shouldShowPromptNow();
      if (!mounted || !shouldShow) return;

      final result = await RateAppDialog.show(context);
      final action = result == true
          ? 'yes'
          : result == false
          ? 'no'
          : 'dismiss';
      unawaited(
        GetIt.I.get<AppAnalytics>().log(
          RatePromptActionEvent(source: 'home_rate_prompt', action: action),
        ),
      );

      if (result == true) {
        await policy.recordAccepted();
        final opened = await GetIt.I.get<RateReviewLauncher>().requestReview();
        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t.settings.couldNotOpenStorePage)),
          );
        }
        return;
      }

      if (result == false) {
        await policy.recordDeclined();
        return;
      }

      await policy.recordDismissed();
    } finally {
      _isRatePromptInFlight = false;
    }
  }
}

class _NewFeatureNavIcon extends StatelessWidget {
  const _NewFeatureNavIcon({required this.icon, required this.showBadge});

  static const badgeKey = Key('home.learn.geo_quiz_new_dot');

  final IconData icon;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (showBadge)
          PositionedDirectional(
            top: -2,
            end: -7,
            child: DecoratedBox(
              key: badgeKey,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
              child: const SizedBox(width: 9, height: 9),
            ),
          ),
      ],
    );
  }
}
