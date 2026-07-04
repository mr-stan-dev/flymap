import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/analytics/events/share_with_friends_event.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/rating/app_share_service.dart';
import 'package:flymap/rating/native_review_requester.dart';
import 'package:flymap/rating/rate_prompt_policy_service.dart';
import 'package:flymap/repository/feature_announcement_repository.dart';
import 'package:flymap/ui/screens/home/tabs/home/home_tab.dart';
import 'package:flymap/ui/screens/home/tabs/learn/learn_tab.dart';
import 'package:flymap/ui/screens/home/tabs/media/media_tab.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_screen.dart';
import 'package:flymap/ui/screens/settings/settings_screen.dart';
import 'package:flymap/ui/widgets/app_advocacy_dialog.dart';
import 'package:flymap/ui/widgets/rate_app_dialog.dart';
import 'package:get_it/get_it.dart';

enum HomeRootTab { flights, learn, media, settings }

const homeSkyCameraButtonKey = Key('home.sky_camera_button');
const homeFlightsTabKey = Key('home.nav.flights');
const homeLearnTabKey = Key('home.nav.learn');
const homeMediaTabKey = Key('home.nav.media');
const homeSettingsTabKey = Key('home.nav.settings');
const homeLearnGeoQuizDotKey = Key('home.learn.geo_quiz_new_dot');

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
          const MediaTab(),
          const SettingsContent(),
        ],
      ),
      floatingActionButton: HomeRootTab.values[_tabIndex] == HomeRootTab.media
          ? FloatingActionButton(
              key: homeSkyCameraButtonKey,
              heroTag: null,
              tooltip: context.t.home.openSkyCamera,
              onPressed: () => unawaited(_openCamera()),
              child: const Icon(Icons.camera_alt_rounded),
            )
          : null,
      bottomNavigationBar: _HomeBottomBar(
        selectedTab: HomeRootTab.values[_tabIndex],
        showLearnBadge: _showLearnGeoQuizDot,
        onTabSelected: _selectTab,
      ),
    );
  }

  Future<void> _openCamera() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const FlymapSkyCameraScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _selectTab(HomeRootTab nextTab) {
    setState(() {
      _tabIndex = nextTab.index;
      if (nextTab == HomeRootTab.learn && _showLearnGeoQuizDot) {
        _showLearnGeoQuizDot = false;
        _showLearnGeoQuizNewBadge = true;
      }
    });
    if (nextTab == HomeRootTab.learn) {
      unawaited(_markGeoQuizAnnouncementSeen());
    }
    unawaited(_maybePromptForRating());
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
      case HomeRootTab.media:
        return context.t.media.title;
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
      final promptState = await policy.getPromptState();
      if (!mounted || promptState == null) return;

      if (promptState.requiresSentimentAnswer) {
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

        if (result == false) {
          await policy.recordDeclined();
          return;
        }
        if (result != true) {
          await policy.recordDismissed();
          return;
        }

        await policy.recordAccepted();
        if (!mounted) return;
      }

      await _showAppAdvocacyDialog(policy: policy, promptState: promptState);
    } finally {
      _isRatePromptInFlight = false;
    }
  }

  Future<void> _showAppAdvocacyDialog({
    required RatePromptPolicyService policy,
    required RatePromptState promptState,
  }) async {
    final action = await AppAdvocacyDialog.show(
      context,
      showRateAction: promptState.canRequestReview,
      showShareAction: promptState.canShare,
    );
    if (!mounted) return;

    switch (action) {
      case AppAdvocacyAction.share:
        unawaited(
          GetIt.I.get<AppAnalytics>().log(
            const ShareWithFriendsEvent(source: 'home_rate_prompt'),
          ),
        );
        final renderBox = context.findRenderObject() as RenderBox?;
        final origin = renderBox == null
            ? Rect.zero
            : renderBox.localToGlobal(Offset.zero) & renderBox.size;
        final shared = await GetIt.I.get<AppShareService>().shareApp(
          sharePositionOrigin: origin,
        );
        if (shared) await policy.recordAppShared();
        return;
      case AppAdvocacyAction.rate:
        await GetIt.I.get<NativeReviewRequester>().requestReview();
        await policy.recordReviewRequested();
        return;
      case AppAdvocacyAction.notNow:
      case null:
        await policy.recordDismissed();
        return;
    }
  }
}

class _HomeBottomBar extends StatelessWidget {
  const _HomeBottomBar({
    required this.selectedTab,
    required this.showLearnBadge,
    required this.onTabSelected,
  });

  final HomeRootTab selectedTab;
  final bool showLearnBadge;
  final ValueChanged<HomeRootTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.72),
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      selectedIconTheme: const IconThemeData(size: 26),
      unselectedIconTheme: const IconThemeData(size: 24),
      currentIndex: selectedTab.index,
      onTap: (index) => onTabSelected(HomeRootTab.values[index]),
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.flight_outlined, key: homeFlightsTabKey),
          activeIcon: const Icon(Icons.flight, key: homeFlightsTabKey),
          label: context.t.home.tabFlights,
        ),
        BottomNavigationBarItem(
          icon: _LearnNavIcon(
            icon: Icons.school_outlined,
            showBadge: showLearnBadge,
            iconKey: homeLearnTabKey,
          ),
          activeIcon: _LearnNavIcon(
            icon: Icons.school,
            showBadge: showLearnBadge,
            iconKey: homeLearnTabKey,
          ),
          label: context.t.home.tabLearn,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.photo_library_outlined, key: homeMediaTabKey),
          activeIcon: const Icon(Icons.photo_library, key: homeMediaTabKey),
          label: context.t.home.tabMedia,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings_outlined, key: homeSettingsTabKey),
          activeIcon: const Icon(Icons.settings, key: homeSettingsTabKey),
          label: context.t.settings.title,
        ),
      ],
    );
  }
}

class _LearnNavIcon extends StatelessWidget {
  const _LearnNavIcon({
    required this.icon,
    required this.showBadge,
    required this.iconKey,
  });

  final IconData icon;
  final bool showBadge;
  final Key iconKey;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, key: iconKey),
        if (showBadge)
          PositionedDirectional(
            top: -2,
            end: -7,
            child: DecoratedBox(
              key: homeLearnGeoQuizDotKey,
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
