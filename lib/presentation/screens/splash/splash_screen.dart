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
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _loadingController;
  late final AnimationController _pulseController;
  late final AnimationController _particleController;
  late final AnimationController _glowController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _loadingProgress;
  late final Animation<double> _loadingOpacity;
  late final Animation<double> _glowRadius;

  // ✅ Auth check runs in parallel with animations, not after
  late final Future<User?> _authFuture;

  @override
  void initState() {
    super.initState();

    // ✅ Start auth check immediately - parallel with animations
    // Before: checked auth AFTER 2800ms delay
    // Now: auth result ready before animations finish
    _authFuture = Future.microtask(
          () => FirebaseAuth.instance.currentUser,
    );

    _initControllers();
    _initAnimations();
    _startSequence();
  }

  void _initControllers() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // ✅ 800→600ms
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // ✅ 700→500ms
    );
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400), // ✅ 1800→1400ms
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

    _loadingProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
    _loadingOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    _glowRadius = Tween<double>(begin: 40, end: 70).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startSequence() async {
    // ✅ Reduced delays: 200+500+400 = 1100ms → 150+350+300 = 800ms
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _loadingController.forward();

    // ✅ Wait for loading bar + auth result simultaneously
    // Total splash: ~1800ms vs original 2800ms
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1400)),
      _authFuture, // ✅ already running since initState
    ]);

    if (!mounted) return;

    final user = await _authFuture;
    if (user != null) {
      Get.offAllNamed(AppRoutes.DASHBOARD);
    } else {
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
    // ✅ Read size once
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: Stack(
        children: [
          // ✅ Static glows in own RepaintBoundary
          RepaintBoundary(
            child: _buildBackgroundGlow(size),
          ),

          // ✅ Particles in own RepaintBoundary
          RepaintBoundary(
            child: Stack(children: _buildParticles(size)),
          ),

          // ✅ Main content
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

          // ✅ Loading bar
          Positioned(
            bottom: 72,
            left: 0,
            right: 0,
            child: RepaintBoundary(child: _buildLoadingSection()),
          ),

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

  Widget _buildBackgroundGlow(Size size) {
    return Stack(
      children: [
        Positioned(
          top: size.height * 0.05,
          left: size.width * 0.5 - 150,
          // ✅ Glow animation is decorative - removed AnimatedBuilder
          // Static glow looks identical, saves repeated rebuilds
          child: Container(
            width: 300,
            height: 300,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x236366F1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: size.height * 0.1,
          right: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x1710B981),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildParticles(Size size) {
    // ✅ const positions
    const positions = [
      [0.15, 0.20],
      [0.28, 0.45],
      [0.41, 0.28],
      [0.54, 0.55],
      [0.67, 0.22],
      [0.80, 0.42],
    ];

    return List.generate(6, (i) {
      final particleSize = 4.0 + i * 2;
      final opacity = 0.20 + i * 0.05;
      return Positioned(
        left: size.width * positions[i][0],
        top: size.height * positions[i][1],
        child: AnimatedBuilder(
          animation: _particleController,
          builder: (_, __) {
            final offset = math.sin(
              _particleController.value * math.pi * 2 + i * 0.8,
            ) *
                10;
            return Transform.translate(
              offset: Offset(0, offset),
              child: Opacity(
                opacity: (0.3 +
                    (math.sin(
                      _particleController.value *
                          math.pi *
                          2 +
                          i,
                    ) *
                        0.5 +
                        0.5) *
                        opacity)
                    .clamp(0.0, 1.0),
                child: Container(
                  width: particleSize,
                  height: particleSize,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6366F1),
                    shape: BoxShape.circle,
                    // ✅ Removed boxShadow from animated widget
                    // boxShadow recalculates every frame = expensive
                    // Visual difference is negligible at 4-12px size
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoOpacity,
      child: SlideTransition(
        position: _logoSlide,
        child: ScaleTransition(
          scale: _logoScale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ✅ Glow ring uses glowController directly
              AnimatedBuilder(
                animation: _glowController,
                builder: (_, __) => Container(
                  width: 68 + _glowRadius.value,
                  height: 68 + _glowRadius.value,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0x266366F1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Main icon - static, no animation needed
              AnimatedBuilder(
                animation: _glowController,
                builder: (_, child) => Container(
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
                        color: const Color(0xFF6366F1)
                            .withValues(alpha: 0.45),
                        blurRadius: _glowRadius.value,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: child,
                ),
                child: const Center(child: _TrendingUpIcon()),
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
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.7),
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
  }

  Widget _buildAppName() {
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
  }

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
                        Container(color: Colors.white.withValues(alpha: 0.08)),
                        FractionallySizedBox(
                          widthFactor: _loadingProgress.value,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
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
              const _PulsingText(),
            ],
          ),
        );
      },
    );
  }
}

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
  // ✅ Cached paint - created once
  static final _paint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(size.width * 0.08, size.height * 0.72);
    path.lineTo(size.width * 0.35, size.height * 0.45);
    path.lineTo(size.width * 0.55, size.height * 0.58);
    path.lineTo(size.width * 0.88, size.height * 0.25);
    canvas.drawPath(path, _paint);

    final arrowPath = Path();
    arrowPath.moveTo(size.width * 0.65, size.height * 0.25);
    arrowPath.lineTo(size.width * 0.88, size.height * 0.25);
    arrowPath.lineTo(size.width * 0.88, size.height * 0.48);
    canvas.drawPath(arrowPath, _paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ✅ Removed controller prop - manages own animation
class _PulsingText extends StatefulWidget {
  const _PulsingText();

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