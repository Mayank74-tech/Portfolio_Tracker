// lib/presentation/screens/finance/bank_connect_flow.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/finance_controller.dart';
import '../../../data/services/remote/mock_bank_service.dart';

class BankConnectFlow extends StatefulWidget {
  const BankConnectFlow({super.key});

  @override
  State<BankConnectFlow> createState() => _BankConnectFlowState();
}

class _BankConnectFlowState extends State<BankConnectFlow>
    with SingleTickerProviderStateMixin {
  late final FinanceController _fc;
  final PageController _pageController = PageController();
  late final AnimationController _stepAnim;

  int _currentStep = 0;

  // Step 1
  Map<String, String>? _selectedBank;

  // Step 2
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountFocus = FocusNode();
  final _ifscFocus = FocusNode();
  String _accountType = 'savings';

  // ✅ Cached values that survive controller clears
  String _cachedAccountLast4 = '****';
  String _cachedBankName = '';
  String _cachedBankLogo = '🏦';

  // Step 3
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  int _resendCountdown = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fc = Get.find<FinanceController>();
    _stepAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _accountFocus.dispose();
    _ifscFocus.dispose();
    _stepAnim.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
      _errorMessage = null;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    _stepAnim.forward(from: 0);
  }

  // ✅ Safe last-4 helper - works even if controller text is cleared
  String _lastFour(String text) {
    if (text.length < 4) return '****';
    return text.substring(text.length - 4);
  }

  // ── Handlers ────────────────────────────────────────────────────────────

  Future<void> _handleInitiate() async {
    final account = _accountController.text.trim();
    final ifsc = _ifscController.text.trim().toUpperCase();

    if (account.length < 9) {
      setState(() => _errorMessage =
      'Account number must be at least 9 digits');
      return;
    }
    if (ifsc.length != 11) {
      setState(() => _errorMessage =
      'IFSC must be 11 characters (e.g. HDFC0001234)');
      return;
    }

    final success = await _fc.initiateConnection(
      bankId: _selectedBank!['id']!,
      accountNumber: account,
      ifsc: ifsc,
    );

    if (!mounted) return;

    if (success) {
      // ✅ Cache values BEFORE moving to OTP step
      // These survive even if controllers get cleared later
      _cachedAccountLast4 = _lastFour(account);
      _cachedBankName = _selectedBank?['name'] ?? 'Bank';
      _cachedBankLogo = _selectedBank?['logo'] ?? '🏦';

      _goToStep(2);
      _startResendCountdown();
    } else {
      setState(() => _errorMessage = _fc.errorMessage.value);
    }
  }

  Future<void> _handleVerify() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Enter the 6-digit OTP');
      return;
    }

    final success = await _fc.verifyOtpAndConnect(
      otp: otp,
      accountType: _accountType,
    );

    if (!mounted) return;

    if (success) {
      _goToStep(3);
    } else {
      setState(() => _errorMessage = _fc.errorMessage.value);
      for (final c in _otpControllers) {
        c.clear();
      }
      _otpFocusNodes[0].requestFocus();
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0) return;

    final success = await _fc.resendOtp();
    if (!mounted) return;

    if (success) {
      _startResendCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('New OTP sent successfully'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 30);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCountdown--);
      return _resendCountdown > 0;
    });
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1SelectBank(),
                  _buildStep2EnterDetails(),
                  _buildStep3VerifyOtp(),
                  _buildStep4Success(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ─────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_currentStep > 0 && _currentStep < 3) {
                _goToStep(_currentStep - 1);
              } else {
                _fc.cancelConnection();
                Get.back();
              }
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF131D2E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFFCBD5E1),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stepTitle(),
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Step ${_currentStep + 1} of 4',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (_currentStep < 3)
            GestureDetector(
              onTap: () {
                _fc.cancelConnection();
                Get.back();
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF131D2E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF94A3B8),
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _stepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Choose Bank';
      case 1:
        return 'Account Details';
      case 2:
        return 'Verify OTP';
      case 3:
        return 'All Set!';
      default:
        return '';
    }
  }

  // ── Step Indicator ──────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i <= _currentStep;
          final isCompleted = i < _currentStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 3 ? 6 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: isActive
                      ? LinearGradient(
                    colors: isCompleted
                        ? [
                      const Color(0xFF10B981),
                      const Color(0xFF059669),
                    ]
                        : [
                      const Color(0xFF0EA5E9),
                      const Color(0xFF0284C7),
                    ],
                  )
                      : null,
                  color: isActive
                      ? null
                      : Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // STEP 1: SELECT BANK
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildStep1SelectBank() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const Text(
          'Which bank do you use?',
          style: TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select your bank to securely link your account',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: MockBankService.availableBanks.length,
          itemBuilder: (_, i) {
            final bank = MockBankService.availableBanks[i];
            final isSelected = _selectedBank?['id'] == bank['id'];

            return GestureDetector(
              onTap: () {
                setState(() => _selectedBank = bank);
                Future.delayed(
                  const Duration(milliseconds: 250),
                      () => _goToStep(1),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0EA5E9),
                      Color(0xFF0284C7),
                    ],
                  )
                      : null,
                  color: isSelected ? null : const Color(0xFF131D2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0EA5E9)
                        : Colors.white.withValues(alpha: 0.06),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9)
                          .withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : const Color(0xFF0EA5E9)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          bank['logo']!,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      bank['name']!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFF1F5F9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bank['ifscPrefix']!,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.7)
                            : const Color(0xFF64748B),
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        _buildInfoCard(
          icon: Icons.shield_outlined,
          title: 'Bank-level security',
          subtitle:
          'Your credentials are never stored. This is a demo using mock data only.',
          color: const Color(0xFF10B981),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // STEP 2: ENTER DETAILS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildStep2EnterDetails() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (_selectedBank != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _selectedBank!['logo']!,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedBank!['name']!,
                          style: const TextStyle(
                            color: Color(0xFFF1F5F9),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'Selected bank',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _goToStep(0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 28),

          const Text(
            'Enter account details',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'We need your account number and IFSC code to verify',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 28),

          _buildLabel('Account Number', icon: Icons.account_balance_rounded),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _accountController,
            focusNode: _accountFocus,
            hint: 'Enter 9-18 digit account number',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(18),
            ],
          ),

          const SizedBox(height: 20),

          _buildLabel('IFSC Code', icon: Icons.qr_code_2_rounded),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _ifscController,
            focusNode: _ifscFocus,
            hint: '${_selectedBank?['ifscPrefix'] ?? 'XXXX'}0001234',
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(11),
              _UpperCaseFormatter(),
            ],
          ),

          const SizedBox(height: 20),

          _buildLabel('Account Type',
              icon: Icons.account_balance_wallet_rounded),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTypeChip('savings', 'Savings', '💰')),
              const SizedBox(width: 12),
              Expanded(child: _buildTypeChip('current', 'Current', '💼')),
            ],
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorBox(_errorMessage!),
          ],

          const SizedBox(height: 28),

          Obx(() => _buildPrimaryButton(
            label: 'Send OTP',
            onTap: _handleInitiate,
            icon: Icons.send_rounded,
            isLoading: _fc.isConnecting.value,
          )),

          const SizedBox(height: 16),

          _buildInfoCard(
            icon: Icons.info_outline_rounded,
            title: 'Demo mode',
            subtitle:
            'Use any 9-18 digit number with matching IFSC prefix',
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // STEP 3: VERIFY OTP
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildStep3VerifyOtp() {
    // ✅ Use cached value (set in _handleInitiate) instead of re-reading controller
    final last4 = _cachedAccountLast4;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (_, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sms_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Center(
          child: Text(
            'Enter verification code',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'OTP sent to mobile linked with\n'),
                const TextSpan(text: 'account ending in '),
                TextSpan(
                  text: last4,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            final isFilled = _otpControllers[i].text.isNotEmpty;
            return SizedBox(
              width: 50,
              height: 60,
              child: TextField(
                controller: _otpControllers[i],
                focusNode: _otpFocusNodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: isFilled
                      ? const Color(0xFF0EA5E9).withValues(alpha: 0.08)
                      : const Color(0xFF131D2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isFilled
                          ? const Color(0xFF0EA5E9)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isFilled
                          ? const Color(0xFF0EA5E9)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF0EA5E9),
                      width: 2,
                    ),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  setState(() {});
                  if (value.isNotEmpty && i < 5) {
                    _otpFocusNodes[i + 1].requestFocus();
                  } else if (value.isEmpty && i > 0) {
                    _otpFocusNodes[i - 1].requestFocus();
                  }
                  if (i == 5 && value.isNotEmpty) {
                    final otp = _otpControllers.map((c) => c.text).join();
                    if (otp.length == 6) {
                      FocusScope.of(context).unfocus();
                      _handleVerify();
                    }
                  }
                },
              ),
            );
          }),
        ),

        Obx(() {
          final otp = _fc.currentDemoOtp.value;
          if (otp.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: GestureDetector(
              onTap: () {
                for (int i = 0; i < 6 && i < otp.length; i++) {
                  _otpControllers[i].text = otp[i];
                }
                setState(() {});
                FocusScope.of(context).unfocus();
                _handleVerify();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFFFBBF24),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Demo OTP: $otp',
                            style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const Text(
                            'Tap to auto-fill',
                            style: TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.touch_app_rounded,
                      color: Color(0xFFFBBF24),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          _buildErrorBox(_errorMessage!),
        ],

        const SizedBox(height: 24),

        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Didn't receive code? ",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              GestureDetector(
                onTap: _resendCountdown > 0 ? null : _handleResendOtp,
                child: Text(
                  _resendCountdown > 0
                      ? 'Resend in ${_resendCountdown}s'
                      : 'Resend OTP',
                  style: TextStyle(
                    color: _resendCountdown > 0
                        ? const Color(0xFF475569)
                        : const Color(0xFF0EA5E9),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Obx(() => _buildPrimaryButton(
          label: 'Verify & Connect',
          onTap: _handleVerify,
          icon: Icons.check_rounded,
          isLoading: _fc.isVerifying.value,
        )),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // STEP 4: SUCCESS (FIXED - uses cached values)
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildStep4Success() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'Account Connected!',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your $_cachedBankName account has been\n'
                'successfully linked to InvestIQ',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF131D2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _cachedBankLogo,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _cachedBankName,
                        style: const TextStyle(
                          color: Color(0xFFF1F5F9),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        // ✅ FIXED: uses cached last 4 digits
                        '${_accountType.toUpperCase()} · XXXX $_cachedAccountLast4',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        color: Color(0xFF10B981),
                        size: 6,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          _buildPrimaryButton(
            label: 'Go to Dashboard',
            onTap: () => Get.back(),
            icon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // REUSABLE WIDGETS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildLabel(String text, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: const Color(0xFF64748B), size: 14),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        color: Color(0xFFF1F5F9),
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color(0xFF131D2E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF0EA5E9),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String value, String label, String emoji) {
    final isSelected = _accountType == value;
    return GestureDetector(
      onTap: () => setState(() => _accountType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          )
              : null,
          color: isSelected ? null : const Color(0xFF131D2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0EA5E9)
                : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : const Color(0xFFCBD5E1),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
    required IconData icon,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          ),
          boxShadow: isLoading
              ? null
              : [
            BoxShadow(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}