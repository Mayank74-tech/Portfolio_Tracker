import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // --- Controllers ---
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _loadingController;
  late final AnimationController _pulseController;
  late final AnimationController _particleController;
  late final AnimationController _glowController;

  // --- Logo animations ---
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;

  // --- Text animations ---
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleOpacity;

  // --- Loading bar ---
  late final Animation<double> _loadingProgress;
  late final Animation<double> _loadingOpacity;

  // --- Glow pulse ---
  late final Animation<double> _glowRadius;

  // --- Particle float ---
  late final Animation<double> _particleFloat;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initAnimations();
    _startSequence();
  }

  void _initControllers() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  void _initAnimations() {
    // Logo
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    // Text
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _subtitleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    // Loading bar
    _loadingProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
    _loadingOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    // Glow
    _glowRadius = Tween<double>(begin: 40, end: 70).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Particle
    _particleFloat = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startSequence() async {
    // Logo entrance
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    // Text entrance
    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();

    // Loading bar
    await Future.delayed(const Duration(milliseconds: 400));
    _loadingController.forward();

    // Navigate after splash
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    // ── Check Firebase auth state ──
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Already logged in → skip login & onboarding
      Get.offAllNamed(AppRoutes.DASHBOARD);
    } else {
      // First time or logged out → show onboarding
      Get.offNamed(AppRoutes.ONBOARDING);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: Stack(
        children: [
          // ── Ambient background glows ──
          _buildBackgroundGlow(size),

          // ── Floating particles ──
          ..._buildParticles(size),

          // ── Main content ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogo(),
                const SizedBox(height: 28),
                _buildAppName(),
              ],
            ),
          ),

          // ── Loading bar at bottom ──
          Positioned(
            bottom: 72,
            left: 0,
            right: 0,
            child: _buildLoadingSection(),
          ),

          // ── Version tag ──
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'v1.0.0',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Background ambient glows ──
  Widget _buildBackgroundGlow(Size size) {
    return Stack(
      children: [
        // Top center purple glow
        Positioned(
          top: size.height * 0.05,
          left: size.width * 0.5 - 150,
          child: AnimatedBuilder(
            animation: _glowRadius,
            builder: (_, __) => Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        // Bottom right green glow
        Positioned(
          bottom: size.height * 0.1,
          right: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF10B981).withOpacity(0.09),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Floating particles ──
  List<Widget> _buildParticles(Size size) {
    final positions = [
      [0.15, 0.20],
      [0.28, 0.45],
      [0.41, 0.28],
      [0.54, 0.55],
      [0.67, 0.22],
      [0.80, 0.42],
    ];
    return List.generate(6, (i) {
      final double particleSize = 4.0 + i * 2;
      final opacity = 0.20 + i * 0.05;
      return Positioned(
        left: size.width * positions[i][0],
        top: size.height * positions[i][1],
        child: AnimatedBuilder(
          animation: _particleController,
          builder: (_, __) {
            final offset = math.sin(
              (_particleController.value * math.pi * 2) + i * 0.8,
            ) *
                10;
            return Transform.translate(
              offset: Offset(0, offset),
              child: Opacity(
                opacity: 0.3 + (math.sin(
                  (_particleController.value * math.pi * 2) + i,
                ) *
                    0.5 +
                    0.5) *
                    opacity,
                child: Container(
                  width: particleSize,
                  height: particleSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // ── Logo icon ──
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _glowController]),
      builder: (_, __) {
        return FadeTransition(
          opacity: _logoOpacity,
          child: SlideTransition(
            position: _logoSlide,
            child: ScaleTransition(
              scale: _logoScale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (_, __) => Container(
                      width: 108 + (_glowRadius.value - 40),
                      height: 108 + (_glowRadius.value - 40),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF6366F1).withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Main icon box
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF4F46E5),
                          Color(0xFF7C3AED),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.45),
                          blurRadius: _glowRadius.value,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          blurRadius: _glowRadius.value * 1.8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: _TrendingUpIcon(),
                    ),
                  ),
                  // Green sparkle dot
                  Positioned(
                    top: 10,
                    right: 10,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) => Transform.scale(
                        scale: 1.0 + _pulseController.value * 0.35,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0B1120),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.7),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── App name + tagline ──
  Widget _buildAppName() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (_, __) {
        return Column(
          children: [
            FadeTransition(
              opacity: _titleOpacity,
              child: SlideTransition(
                position: _titleSlide,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF1F5F9),
                      Color(0xFFC7D2FE),
                      Color(0xFFA5B4FC),
                    ],
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: const Text(
                    'InvestIQ',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            FadeTransition(
              opacity: _subtitleOpacity,
              child: const Text(
                'Track smarter. Invest wiser.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Loading bar section ──
  Widget _buildLoadingSection() {
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (_, __) {
        return FadeTransition(
          opacity: _loadingOpacity,
          child: Column(
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 150,
                    height: 3,
                    child: Stack(
                      children: [
                        // Track
                        Container(
                          color: Colors.white.withOpacity(0.08),
                        ),
                        // Fill
                        FractionallySizedBox(
                          widthFactor: _loadingProgress.value,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF818CF8),
                                  Color(0xFF10B981),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _PulsingText(controller: _loadingController),
            ],
          ),
        );
      },
    );
  }
}

// ── Custom TrendingUp icon drawn with canvas ──
class _TrendingUpIcon extends StatelessWidget {
  const _TrendingUpIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(44, 44),
      painter: _TrendingUpPainter(),
    );
  }
}

class _TrendingUpPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Trending line: bottom-left to top-right
    path.moveTo(size.width * 0.08, size.height * 0.72);
    path.lineTo(size.width * 0.35, size.height * 0.45);
    path.lineTo(size.width * 0.55, size.height * 0.58);
    path.lineTo(size.width * 0.88, size.height * 0.25);

    canvas.drawPath(path, paint);

    // Arrow head
    final arrowPath = Path();
    arrowPath.moveTo(size.width * 0.65, size.height * 0.25);
    arrowPath.lineTo(size.width * 0.88, size.height * 0.25);
    arrowPath.lineTo(size.width * 0.88, size.height * 0.48);

    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Pulsing "Loading your portfolio..." text ──
class _PulsingText extends StatefulWidget {
  final AnimationController controller;
  const _PulsingText({required this.controller});

  @override
  State<_PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<_PulsingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: const Text(
          'Loading your portfolio...',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF475569),
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}