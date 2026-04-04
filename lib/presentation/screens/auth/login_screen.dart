import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/routes/app_routes.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── State ──
  bool _isLogin = true;
  bool _showPassword = false;
  final _emailController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');
  final _nameController = TextEditingController();

  // ── Focus nodes ──
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _nameFocus = FocusNode();

  // ── Active field tracking (for border highlight) ──
  bool _emailActive = false;
  bool _passwordActive = false;
  bool _nameActive = false;

  // ── Animation controllers ──
  late final AnimationController _headerController;
  late final AnimationController _formController;
  late final AnimationController _nameFieldController;
  late final AnimationController _buttonController;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _nameFieldHeight;
  late final Animation<double> _nameFieldOpacity;
  late final Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initFocusListeners();
    _playEntrance();
  }

  void _initAnimations() {
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _nameFieldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeIn,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _formFade = CurvedAnimation(
      parent: _formController,
      curve: Curves.easeIn,
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
    );

    _nameFieldHeight = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _nameFieldController, curve: Curves.easeInOut),
    );
    _nameFieldOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _nameFieldController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _buttonScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeIn),
    );
  }

  void _initFocusListeners() {
    _emailFocus.addListener(() {
      setState(() => _emailActive = _emailFocus.hasFocus);
    });
    _passwordFocus.addListener(() {
      setState(() => _passwordActive = _passwordFocus.hasFocus);
    });
    _nameFocus.addListener(() {
      setState(() => _nameActive = _nameFocus.hasFocus);
    });
  }

  Future<void> _playEntrance() async {
    _headerController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _formController.forward();
  }

  void _toggleTab(bool isLogin) {
    setState(() => _isLogin = isLogin);
    if (!isLogin) {
      _nameFieldController.forward();
    } else {
      _nameFieldController.reverse();
    }
  }

  Future<void> _handleSubmit() async {
    await _buttonController.forward();
    await _buttonController.reverse();
    // Navigate to dashboard
    Get.offAllNamed(AppRoutes.DASHBOARD);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _nameFocus.dispose();
    _headerController.dispose();
    _formController.dispose();
    _nameFieldController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──
                    _buildHeader(),

                    // ── Tab toggle ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: _buildTabToggle(),
                    ),

                    // ── Form ──
                    _buildForm(),

                    // ── Terms ──
                    _buildTerms(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF130B2E), Color(0xFF0B1120)],
            ),
          ),
          child: Column(
            children: [
              // Logo icon
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: _TrendingUpMini(),
                ),
              ),
              const SizedBox(height: 14),
              // Title
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _isLogin ? 'Welcome back' : 'Create account',
                  key: ValueKey(_isLogin),
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _isLogin
                      ? 'Sign in to your InvestIQ account'
                      : 'Start your investment journey',
                  key: ValueKey('sub$_isLogin'),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TAB TOGGLE
  // ─────────────────────────────────────────────
  Widget _buildTabToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: ['Login', 'Sign Up'].asMap().entries.map((entry) {
          final i = entry.key;
          final label = entry.value;
          final isActive = _isLogin == (i == 0);
          return Expanded(
            child: GestureDetector(
              onTap: () => _toggleTab(i == 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF6366F1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isActive
                      ? [
                    BoxShadow(
                      color:
                      const Color(0xFF6366F1).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                      : null,
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : const Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: isActive
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  FORM
  // ─────────────────────────────────────────────
  Widget _buildForm() {
    return FadeTransition(
      opacity: _formFade,
      child: SlideTransition(
        position: _formSlide,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Name field (sign up only) ──
              AnimatedBuilder(
                animation: _nameFieldController,
                builder: (_, __) => ClipRect(
                  child: Align(
                    heightFactor: _nameFieldHeight.value,
                    child: Opacity(
                      opacity: _nameFieldOpacity.value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildField(
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          controller: _nameController,
                          focusNode: _nameFocus,
                          isActive: _nameActive,
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Email ──
              _buildField(
                label: 'Email Address',
                hint: 'Enter your email',
                controller: _emailController,
                focusNode: _emailFocus,
                isActive: _emailActive,
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                accentBorder: true,
              ),
              const SizedBox(height: 16),

              // ── Password ──
              _buildField(
                label: 'Password',
                hint: 'Enter your password',
                controller: _passwordController,
                focusNode: _passwordFocus,
                isActive: _passwordActive,
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
              ),

              // ── Forgot password ──
              if (_isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 22),

              // ── Submit button ──
              ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 0.96).animate(
                  CurvedAnimation(
                    parent: _buttonController,
                    curve: Curves.easeIn,
                  ),
                ),
                child: GestureDetector(
                  onTap: _handleSubmit,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.38),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin ? 'Sign In' : 'Create Account',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Divider ──
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR CONTINUE WITH',
                      style: TextStyle(
                        color: const Color(0xFF475569),
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Google button ──
              GestureDetector(
                onTap: () => Get.offAllNamed(AppRoutes.DASHBOARD),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF131D2E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _GoogleLogo(),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  REUSABLE FIELD
  // ─────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isActive,
    required IconData prefixIcon,
    bool isPassword = false,
    bool accentBorder = false,
    TextInputType? keyboardType,
  }) {
    final borderColor = isActive
        ? const Color(0xFF6366F1)
        : accentBorder
        ? const Color(0xFF6366F1).withOpacity(0.4)
        : Colors.white.withOpacity(0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF131D2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: isActive
                ? [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.12),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ]
                : null,
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(
                prefixIcon,
                size: 18,
                color: isActive
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: isPassword && !_showPassword,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  cursorColor: const Color(0xFF6366F1),
                ),
              ),
              if (isPassword)
                GestureDetector(
                  onTap: () =>
                      setState(() => _showPassword = !_showPassword),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                )
              else
                const SizedBox(width: 16),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  TERMS
  // ─────────────────────────────────────────────
  Widget _buildTerms() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(
            color: Color(0xFF334155),
            fontSize: 11,
            height: 1.6,
          ),
          children: [
            TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(
              text: 'Terms of Service',
              style: TextStyle(color: Color(0xFF6366F1)),
            ),
            TextSpan(text: ' & '),
            TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(color: Color(0xFF6366F1)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Mini trending up icon (CustomPaint)
// ─────────────────────────────────────────────
class _TrendingUpMini extends StatelessWidget {
  const _TrendingUpMini();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(28, 28),
      painter: _TrendingUpMiniPainter(),
    );
  }
}

class _TrendingUpMiniPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.72)
      ..lineTo(size.width * 0.35, size.height * 0.45)
      ..lineTo(size.width * 0.55, size.height * 0.58)
      ..lineTo(size.width * 0.88, size.height * 0.25);
    canvas.drawPath(path, paint);

    final arrow = Path()
      ..moveTo(size.width * 0.65, size.height * 0.25)
      ..lineTo(size.width * 0.88, size.height * 0.25)
      ..lineTo(size.width * 0.88, size.height * 0.48);
    canvas.drawPath(arrow, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────
//  Google logo (Canvas-drawn, no SVG package)
// ─────────────────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    // Blue arc (top-right)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
      -1.1,
      2.2,
      false,
      bluePaint,
    );

    // Green arc (bottom)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
      1.1,
      1.6,
      false,
      greenPaint,
    );

    // Yellow arc (bottom-left)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
      2.7,
      1.6,
      false,
      yellowPaint,
    );

    // Red arc (top-left)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
      -2.7,
      1.6,
      false,
      redPaint,
    );

    // White horizontal bar (G cutout)
    final barPaint = Paint()
      ..color = const Color(0xFF131D2E)
      ..strokeWidth = size.width * 0.2
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.72, cy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}