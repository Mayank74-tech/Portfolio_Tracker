import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/routes/app_routes.dart';

// ─────────────────────────────────────────────
//  Data model for each onboarding slide
// ─────────────────────────────────────────────
class _OnboardingSlide {
  final String title;
  final String subtitle;
  final String description;
  final Color accentColor;
  final Color accentColorLight;
  final IconData icon;
  final List<double> bars;
  final List<Color> barColors;

  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.accentColor,
    required this.accentColorLight,
    required this.icon,
    required this.bars,
    required this.barColors,
  });
}

final _slides = [
  _OnboardingSlide(
    title: 'Track All Investments',
    subtitle: 'ACROSS PLATFORMS',
    description:
    'Connect Zerodha, Groww, Angel One and more. View your entire portfolio across all brokers in one beautiful dashboard.',
    accentColor: const Color(0xFF6366F1),
    accentColorLight: const Color(0xFF818CF8),
    icon: Icons.bar_chart_rounded,
    bars: [65, 85, 45, 90, 70, 55, 80],
    barColors: [
      Color(0xFF6366F1),
      Color(0xFF818CF8),
      Color(0xFFC7D2FE),
    ],
  ),
  _OnboardingSlide(
    title: 'AI-Powered Insights',
    subtitle: 'UNDERSTAND INSTANTLY',
    description:
    'Ask questions about your portfolio in plain language. Get instant AI analysis powered by Llama 3 running locally on your device.',
    accentColor: const Color(0xFF10B981),
    accentColorLight: const Color(0xFF34D399),
    icon: Icons.psychology_rounded,
    bars: [40, 75, 60, 85, 50, 90, 65],
    barColors: [
      Color(0xFF10B981),
      Color(0xFF34D399),
      Color(0xFF6EE7B7),
    ],
  ),
  _OnboardingSlide(
    title: 'Make Smarter Decisions',
    subtitle: 'GROW YOUR WEALTH',
    description:
    'Get AI-driven recommendations, sector diversification tips, and actionable insights to achieve your financial goals.',
    accentColor: const Color(0xFFF59E0B),
    accentColorLight: const Color(0xFFFCD34D),
    icon: Icons.track_changes_rounded,
    bars: [50, 60, 75, 85, 90, 88, 95],
    barColors: [
      Color(0xFFF59E0B),
      Color(0xFFFCD34D),
      Color(0xFFFEF3C7),
    ],
  ),
];

// ─────────────────────────────────────────────
//  Onboarding Screen
// ─────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // Per-page animation controller (re-triggered on page change)
  late AnimationController _slideEnterController;
  late AnimationController _barsController;
  late AnimationController _iconFloatController;
  late AnimationController _buttonController;
  late AnimationController _bgGlowController;

  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _barScale;
  late Animation<double> _iconFloat;
  late Animation<double> _buttonScale;
  late Animation<double> _bgGlow;

  @override
  void initState() {
    super.initState();

    _slideEnterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _barsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _iconFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bgGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(
      parent: _slideEnterController,
      curve: Curves.easeIn,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideEnterController, curve: Curves.easeOutCubic),
    );
    _barScale = CurvedAnimation(
      parent: _barsController,
      curve: Curves.easeOutBack,
    );
    _iconFloat = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _iconFloatController, curve: Curves.easeInOut),
    );
    _buttonScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.elasticOut),
    );
    _bgGlow = Tween<double>(begin: 0.08, end: 0.18).animate(
      CurvedAnimation(parent: _bgGlowController, curve: Curves.easeInOut),
    );

    // Kick off first-slide animations
    _playSlideAnimations();
  }

  void _playSlideAnimations() {
    _slideEnterController.forward(from: 0);
    _barsController.forward(from: 0);
    _buttonController.forward(from: 0);
  }

  void _goToNext() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Get.offNamed(AppRoutes.LOGIN);
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _playSlideAnimations();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideEnterController.dispose();
    _barsController.dispose();
    _iconFloatController.dispose();
    _buttonController.dispose();
    _bgGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: Stack(
        children: [
          // ── Animated background glow ──
          _buildBgGlow(slide, size),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar with skip ──
                _buildTopBar(),

                // ── Page content ──
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      return _buildSlideContent(_slides[index], size);
                    },
                  ),
                ),

                // ── Bottom controls ──
                _buildBottomControls(slide),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Animated background glow ──
  Widget _buildBgGlow(_OnboardingSlide slide, Size size) {
    return AnimatedBuilder(
      animation: _bgGlow,
      builder: (_, __) => AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.3),
            radius: 1.0,
            colors: [
              slide.accentColor.withOpacity(_bgGlow.value),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ──
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Slide counter
          Text(
            '${_currentIndex + 1} / ${_slides.length}',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          // Skip button
          GestureDetector(
            onTap: () => Get.offNamed(AppRoutes.LOGIN),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Slide content ──
  Widget _buildSlideContent(_OnboardingSlide slide, Size size) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Illustration card
              _buildIllustrationCard(slide, size),
              const SizedBox(height: 36),
              // Text content
              _buildTextContent(slide),
            ],
          ),
        ),
      ),
    );
  }

  // ── Illustration card ──
  Widget _buildIllustrationCard(_OnboardingSlide slide, Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 0.30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(
          color: slide.accentColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radial glow behind bars
          Positioned.fill(
            child: Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      slide.accentColor.withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bar chart
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: _buildBarChart(slide),
          ),

          // Floating icon
          Positioned(
            top: 28,
            child: AnimatedBuilder(
              animation: _iconFloat,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _iconFloat.value),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: slide.accentColor.withOpacity(0.15),
                    border: Border.all(
                      color: slide.accentColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: slide.accentColor.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    slide.icon,
                    color: slide.accentColor,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),

          // Decorative grid lines
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(
                color: slide.accentColor.withOpacity(0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bar chart ──
  Widget _buildBarChart(_OnboardingSlide slide) {
    final maxBar = slide.bars.reduce(math.max);
    return AnimatedBuilder(
      animation: _barsController,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(slide.bars.length, (i) {
            final normalised = slide.bars[i] / maxBar;
            final isMax = slide.bars[i] == maxBar;
            final delay = (i / slide.bars.length);
            final progress = math.max(0.0,
                math.min(1.0, (_barScale.value - delay) / (1 - delay)));

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMax)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: slide.accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${slide.bars[i].toInt()}%',
                        style: TextStyle(
                          color: slide.accentColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 20),
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300 + i * 60),
                    width: 20,
                    height: normalised * 80 * progress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isMax
                            ? [slide.accentColorLight, slide.accentColor]
                            : [
                          slide.accentColor.withOpacity(
                              0.15 + (i % 3) * 0.08),
                          slide.accentColor.withOpacity(
                              0.08 + (i % 3) * 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ── Text content ──
  Widget _buildTextContent(_OnboardingSlide slide) {
    return Column(
      children: [
        // Subtitle chip
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: slide.accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: slide.accentColor.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Text(
            slide.subtitle,
            style: TextStyle(
              color: slide.accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Title
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 14),

        // Description
        Text(
          slide.description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ── Bottom controls ──
  Widget _buildBottomControls(_OnboardingSlide slide) {
    final isLast = _currentIndex == _slides.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
      child: Column(
        children: [
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final isActive = i == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? slide.accentColor
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isActive
                      ? [
                    BoxShadow(
                      color: slide.accentColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Next / Get Started button
          ScaleTransition(
            scale: _buttonScale,
            child: GestureDetector(
              onTap: _goToNext,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isLast
                        ? [slide.accentColor, slide.accentColorLight]
                        : const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isLast ? slide.accentColor : const Color(0xFF6366F1))
                          .withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLast ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Grid background painter for illustration
// ─────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8;

    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.color != color;
}