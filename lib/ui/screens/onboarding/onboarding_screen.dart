import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/onboarding/onboarding_step.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_progress_indicator.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_step_content.dart';
import 'package:get_it/get_it.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _steps = OnboardingStep.values;
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  bool _isFinishing = false;

  bool get _isLastPage => _pageIndex == _steps.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  itemCount: _steps.length,
                  onPageChanged: (index) {
                    setState(() {
                      _pageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return OnboardingStepContent(step: _steps[index]);
                  },
                ),
              ),
              OnboardingProgressIndicator(
                count: _steps.length,
                activeIndex: _pageIndex,
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
}
