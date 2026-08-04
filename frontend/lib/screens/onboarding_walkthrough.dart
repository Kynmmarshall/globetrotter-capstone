import 'package:flutter/material.dart';

import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/themes/trip_colors.dart';
import 'package:trip_io/widgets/brand_logo_lockup.dart';

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

/// A one-time, swipeable walkthrough shown the first time someone reaches
/// the dashboard on this device - introduces the app's four main jobs
/// (browse, get recommendations, plan, navigate) before dropping them into
/// the real UI. Dismissing it (skip or finishing the last page) marks it
/// seen in [SessionController] so it never shows again on this device.
class OnboardingWalkthrough extends StatefulWidget {
  const OnboardingWalkthrough({super.key, required this.session});

  final SessionController session;

  @override
  State<OnboardingWalkthrough> createState() => _OnboardingWalkthroughState();
}

class _OnboardingWalkthroughState extends State<OnboardingWalkthrough> {
  final _pageController = PageController();
  int _page = 0;

  static const double _backgroundBreakpoint = 700;

  List<_OnboardingPageData> _pages(AppLocalizations l10n) => [
    _OnboardingPageData(
      icon: Icons.travel_explore,
      title: l10n.onboardingPage1Title,
      body: l10n.onboardingPage1Body,
    ),
    _OnboardingPageData(
      icon: Icons.star,
      title: l10n.onboardingPage2Title,
      body: l10n.onboardingPage2Body,
    ),
    _OnboardingPageData(
      icon: Icons.event_note,
      title: l10n.onboardingPage3Title,
      body: l10n.onboardingPage3Body,
    ),
    _OnboardingPageData(
      icon: Icons.map,
      title: l10n.onboardingPage4Title,
      body: l10n.onboardingPage4Body,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    widget.session.markOnboardingSeen();
    Navigator.of(context).pop();
  }

  void _next(int pageCount) {
    if (_page == pageCount - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _pages(l10n);
    final isLastPage = _page == pages.length - 1;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < _backgroundBreakpoint;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                isCompact
                    ? 'assets/backgrounds/mobile.png'
                    : 'assets/backgrounds/pc.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
              DecoratedBox(
                decoration: BoxDecoration(color: context.tripColors.scrim),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    const BrandLogoLockup(iconSize: 34),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextButton(
                          onPressed: isLastPage ? null : _finish,
                          child: Text(
                            l10n.onboardingSkip,
                            style: TextStyle(
                              color: isLastPage
                                  ? Colors.transparent
                                  : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: pages.length,
                        onPageChanged: (index) =>
                            setState(() => _page = index),
                        itemBuilder: (context, index) {
                          final page = pages[index];
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 420,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 92,
                                      height: 92,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            Theme.of(
                                              context,
                                            ).colorScheme.tertiary,
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        page.icon,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    Text(
                                      page.title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 22,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      page.body,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14.5,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(pages.length, (index) {
                        final active = index == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      }),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _next(pages.length),
                          child: Text(
                            isLastPage
                                ? l10n.onboardingGetStarted
                                : l10n.onboardingNext,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
