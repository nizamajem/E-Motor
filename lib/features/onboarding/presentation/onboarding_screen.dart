import 'package:flutter/material.dart';

import '../data/onboarding_slide.dart';
import 'widgets/onboarding_card.dart';
import 'widgets/page_indicator.dart';
import '../../auth/presentation/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  final List<OnboardingSlide> _slides = const [
    OnboardingSlide(
      title: 'Welcome Gridwiz E-Motor',
      subtitle: 'A seamless electric mobility powered by real-time technology.',
      imageAsset: 'assets/images/onboard-ride.png',
    ),
    OnboardingSlide(
      title: 'Smart & Connected',
      subtitle:
          'Monitor speed, battery level, and vehicle status in real time.',
      imageAsset: 'assets/images/onboard-smart.png',
    ),
    OnboardingSlide(
      title: 'Unlock, Ride, Go',
      subtitle:
          'Unlock your e-motor easily and begin your ride instantly, just tap, ride, and go.',
      imageAsset: 'assets/images/onboard-unlock.png',
    ),
  ];

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
                itemCount: _slides.length,
                onPageChanged: (value) {
                  setState(() => _pageIndex = value);
                },
                itemBuilder: (context, index) {
                  return OnboardingCard(
                    slide: _slides[index],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _goToLastPage,
          child: const Text(
            'Skip',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isLast = _pageIndex == _slides.length - 1;
    final ctaLabel = isLast ? 'Get Started' : 'Next';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PageIndicator(
            length: _slides.length,
            activeIndex: _pageIndex,
            activeColor: _slides[_pageIndex].primary,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLast ? _handleFinish : _goToNextPage,
              child: Text(ctaLabel),
            ),
          ),
        ],
      ),
    );
  }

  void _goToNextPage() {
    final next = (_pageIndex + 1).clamp(0, _slides.length - 1);
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _goToLastPage() {
    _pageController.animateToPage(
      _slides.length - 1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _handleFinish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }
}
