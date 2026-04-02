import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_window_image.dart';
import 'package:get_it/get_it.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 3;
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  bool _isFinishing = false;

  bool get _isLastPage => _pageIndex == _pageCount - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pages = <_OnboardingPageData>[
      _OnboardingPageData(
        imageAsset: 'assets/images/onboarding1.webp',
        title: context.t.onboarding.page1Title,
        subtitle: context.t.onboarding.page1Subtitle,
      ),
      _OnboardingPageData(
        imageAsset: 'assets/images/onboarding2.webp',
        title: context.t.onboarding.page2Title,
        subtitle: context.t.onboarding.page2Subtitle,
      ),
      _OnboardingPageData(
        imageAsset: 'assets/images/onboarding3.webp',
        title: context.t.onboarding.page3Title,
        subtitle: context.t.onboarding.page3Subtitle,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: _isLastPage
                    ? const SizedBox(height: 40)
                    : TertiaryButton(
                        label: context.t.onboarding.skip,
                        onPressed: _isFinishing ? null : _finishOnboarding,
                        expand: false,
                      ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _pageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final data = pages[index];
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildVisual(context, data),
                            const SizedBox(height: 24),
                            Text(
                              data.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data.subtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pageCount, (index) {
                  final isActive = index == _pageIndex;
                  return AnimatedContainer(
                    duration: DsMotion.fast,
                    curve: DsMotion.fastInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: _isLastPage
                    ? context.t.onboarding.startExploring
                    : context.t.onboarding.next,
                isLoading: _isFinishing,
                onPressed: _isFinishing
                    ? null
                    : () {
                        if (_isLastPage) {
                          _finishOnboarding();
                          return;
                        }
                        _pageController.nextPage(
                          duration: DsMotion.normal,
                          curve: DsMotion.enter,
                        );
                      },
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    setState(() {
      _isFinishing = true;
    });
    await GetIt.I<OnboardingRepository>().markSeen();
    if (!mounted) return;
    AppRouter.goHome(context);
  }

  Widget _buildVisual(BuildContext context, _OnboardingPageData data) {
    return OnboardingWindowImage(assetPath: data.imageAsset);
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
  });

  final String imageAsset;
  final String title;
  final String subtitle;
}
