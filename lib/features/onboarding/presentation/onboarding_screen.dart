import 'package:flutter/material.dart';

import '../data/onboarding_slide.dart';
import 'widgets/onboarding_card.dart';
import 'widgets/page_indicator.dart';
import '../../auth/presentation/login_screen.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/navigation/app_route.dart';
import '../../../core/session/session_manager.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  List<OnboardingSlide> _buildSlides(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      OnboardingSlide(
        title: l10n.onboardTitle1,
        subtitle: l10n.onboardSubtitle1,
        imageAsset: 'assets/images/onboard-ride.png',
      ),
      OnboardingSlide(
        title: l10n.onboardTitle2,
        subtitle: l10n.onboardSubtitle2,
        imageAsset: 'assets/images/onboard-smart.png',
      ),
      OnboardingSlide(
        title: l10n.onboardTitle3,
        subtitle: l10n.onboardSubtitle3,
        imageAsset: 'assets/images/onboard-unlock.png',
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _buildSlides(context).length,
                onPageChanged: (value) {
                  setState(() => _pageIndex = value);
                },
                itemBuilder: (context, index) {
                  final slides = _buildSlides(context);
                  return OnboardingCard(
                    slide: slides[index],
                  );
                },
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => _goToLastPage(_buildSlides(context).length),
          child: Text(
            l10n.skip,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slides = _buildSlides(context);
    final isLast = _pageIndex == slides.length - 1;
    final ctaLabel = isLast ? l10n.getStarted : l10n.next;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PageIndicator(
            length: slides.length,
            activeIndex: _pageIndex,
            activeColor: slides[_pageIndex].primary,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLast
                  ? _handleFinish
                  : () => _goToNextPage(slides.length),
              child: Text(ctaLabel),
            ),
          ),
        ],
      ),
    );
  }

  void _goToNextPage(int length) {
    final next = (_pageIndex + 1).clamp(0, length - 1);
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _goToLastPage(int length) {
    _pageController.animateToPage(
      length - 1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _handleFinish() {
    SessionManager.instance.setOnboardingSeen(true);
    Navigator.of(context).pushReplacement(
      appRoute(
        const LoginScreen(),
        direction: AxisDirection.left,
      ),
    );
  }
}
