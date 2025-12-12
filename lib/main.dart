import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const EMotorApp());
}

class EMotorApp extends StatelessWidget {
  const EMotorApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0B0D11);
    const primary = Color(0xFFFFC857);
    const accent = Color(0xFF30E0A1);

    return MaterialApp(
      title: 'E-Motor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: accent,
          surface: Color(0xFF11141C),
          onSurface: Colors.white,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _pageIndex = 0;

  final List<_OnboardSlide> _slides = const [
    _OnboardSlide(
      title: 'Sewa Instan & Fleksibel',
      description:
          'Ambil e-motor terdekat, pilih durasi menit hingga harian, semua cukup lewat satu ketukan.',
      highlights: [
        'Pick-up 5 menit',
        'Tanpa deposit',
        'Bayar sesuai pemakaian'
      ],
      accent: Color(0xFFFFC857),
      accentSecondary: Color(0xFFB98021),
      icon: Icons.flash_on_rounded,
    ),
    _OnboardSlide(
      title: 'Keamanan & Tracking Live',
      description:
          'Smart lock, GPS, dan proteksi menyeluruh memantau perjalanan Anda dalam waktu nyata.',
      highlights: [
        'Smart lock aman',
        'GPS live tracking',
        'Asuransi perjalanan'
      ],
      accent: Color(0xFF30E0A1),
      accentSecondary: Color(0xFF14B381),
      icon: Icons.shield_moon_rounded,
    ),
    _OnboardSlide(
      title: 'Premium & Selalu Siap',
      description:
          'Unit terawat, baterai prima, concierge 24/7, dan opsi pengantaran langsung ke lokasi.',
      highlights: ['Concierge 24/7', 'Baterai terjaga', 'Antar-jemput motor'],
      accent: Color(0xFF8AB5FF),
      accentSecondary: Color(0xFF4E7BD6),
      icon: Icons.diamond_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _BackgroundAura(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 12),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (index) {
                        setState(() => _pageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return _OnboardCard(slide: slide);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFC857), Color(0xFF30E0A1)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44FFC857),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.electric_moped_rounded,
                  color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'E-Motor',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                ),
                Text(
                  'Penyewaan e-motor premium',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ],
        ),
        TextButton(
          onPressed: () => _goToLastPage(),
          child: const Text(
            'Lewati',
            style:
                TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isLast = _pageIndex == _slides.length - 1;
    final ctaLabel = isLast ? 'Mulai Sekarang' : 'Lanjut';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _PageIndicator(
              length: _slides.length,
              activeIndex: _pageIndex,
              activeColor: _slides[_pageIndex].accent,
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _slides[_pageIndex].accent,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: isLast ? _handleFinish : _goToNextPage,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(ctaLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Nikmati moda bergerak masa kini yang ramah lingkungan dengan layanan concierge eksklusif.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.white70, height: 1.5),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  void _goToNextPage() {
    final next = (_pageIndex + 1).clamp(0, _slides.length - 1);
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _goToLastPage() {
    _pageController.animateToPage(
      _slides.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _handleFinish() {
    // Placeholder for navigation to the main app/dashboard.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Onboarding selesai! Lanjutkan ke dashboard.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _OnboardCard extends StatelessWidget {
  const _OnboardCard({required this.slide});

  final _OnboardSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    slide.accent.withValues(alpha: 0.18),
                    slide.accentSecondary.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF11141C).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 22,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconHalo(accent: slide.accent, icon: slide.icon),
                const SizedBox(height: 20),
                Text(
                  slide.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  slide.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        height: 1.6,
                      ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: slide.highlights
                      .map(
                        (item) => _HighlightChip(
                          label: item,
                          accent: slide.accent,
                          accentSecondary: slide.accentSecondary,
                        ),
                      )
                      .toList(),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [slide.accent, slide.accentSecondary],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.eco_rounded,
                            color: Colors.black87, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Go Electric',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconHalo extends StatelessWidget {
  const _IconHalo({required this.accent, required this.icon});

  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 82,
          width: 82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.18),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 28,
                spreadRadius: 6,
              ),
            ],
          ),
        ),
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                accent,
                accent.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(icon, color: Colors.black87, size: 30),
        ),
      ],
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({
    required this.label,
    required this.accent,
    required this.accentSecondary,
  });

  final String label;
  final Color accent;
  final Color accentSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.18),
            accentSecondary.withValues(alpha: 0.14),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.length,
    required this.activeIndex,
    required this.activeColor,
  });

  final int length;
  final int activeIndex;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(length, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: EdgeInsets.only(right: index == length - 1 ? 0 : 8),
          height: 10,
          width: isActive ? 28 : 12,
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.white12,
            borderRadius: BorderRadius.circular(14),
            border: isActive
                ? Border.all(color: Colors.black.withValues(alpha: 0.2))
                : Border.all(color: Colors.white10),
          ),
        );
      }),
    );
  }
}

class _BackgroundAura extends StatelessWidget {
  const _BackgroundAura();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: const Color(0xFF0B0D11)),
        Positioned(
          top: -120,
          left: -60,
          child: _blurredCircle(const Color(0x33FFC857)),
        ),
        Positioned(
          bottom: -140,
          right: -30,
          child: _blurredCircle(const Color(0x332FD6A2)),
        ),
        Positioned(
          bottom: 160,
          left: -80,
          child: _blurredCircle(const Color(0x332E6CFF)),
        ),
      ],
    );
  }

  Widget _blurredCircle(Color color) {
    return Container(
      height: 260,
      width: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 120,
            spreadRadius: 60,
          ),
        ],
      ),
    );
  }
}

class _OnboardSlide {
  const _OnboardSlide({
    required this.title,
    required this.description,
    required this.highlights,
    required this.accent,
    required this.accentSecondary,
    required this.icon,
  });

  final String title;
  final String description;
  final List<String> highlights;
  final Color accent;
  final Color accentSecondary;
  final IconData icon;
}
