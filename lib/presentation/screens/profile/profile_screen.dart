import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/auth_controller.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/portfolio_controller.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/settings_controller.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/theme_controller.dart';

import '../../../data/services/local/hive_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _biometric = false;

  // ✅ Getters instead of late final - hot-reload safe
  AuthController get _auth => Get.find<AuthController>();
  ThemeController get _themeController => Get.find<ThemeController>();
  SettingsController get _settingsController => Get.find<SettingsController>();
  PortfolioController get _portfolioController =>
      Get.find<PortfolioController>();

  String get _displayName =>
      HiveService.savedName ??
          _auth.firebaseUser.value?.displayName ??
          _auth.firebaseUser.value?.email?.split('@').first ??
          'Investor';

  String get _userEmail =>
      HiveService.savedEmail ?? _auth.firebaseUser.value?.email ?? '';

  String get _initials {
    final parts = _displayName.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'U';
  }

  DateTime? get _joinedDate => _auth.firebaseUser.value?.metadata.creationTime;

  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
    );
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entranceFade,
          child: SlideTransition(
            position: _entranceSlide,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildUserCard()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(child: _buildQuickStats()),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(child: _buildPreferencesSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                SliverToBoxAdapter(child: _buildDataSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                SliverToBoxAdapter(child: _buildAboutSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(child: _buildSignOutButton()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // HEADER
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          GestureDetector(
            onTap: _showEditProfileSheet,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF131D2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF94A3B8),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // USER CARD
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildUserCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1A4F),
              Color(0xFF151030),
              Color(0xFF0F0D2E),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                // Avatar with verified badge
                Stack(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
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
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0F0D2E),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName,
                        style: const TextStyle(
                          color: Color(0xFFF1F5F9),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _userEmail,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6366F1).withValues(alpha: 0.2),
                              const Color(0xFF7C3AED).withValues(alpha: 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF6366F1)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              color: Color(0xFFA5B4FC),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _joinedDate != null
                                  ? 'Member since ${_formatJoinDate(_joinedDate!)}'
                                  : 'Active Member',
                              style: const TextStyle(
                                color: Color(0xFFA5B4FC),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // QUICK STATS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(() {
        final holdings = _portfolioController.holdings.length;
        final summary = _portfolioController.summary;
        final totalValue = _toDouble(summary['total_value']);
        final totalPL = _toDouble(summary['profit_loss']);
        final isPositive = totalPL >= 0;

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.pie_chart_rounded,
                iconColor: const Color(0xFF6366F1),
                label: 'Holdings',
                value: '$holdings',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF0EA5E9),
                label: 'Portfolio',
                value: '₹${_compactNum(totalValue)}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                iconColor: isPositive
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                label: 'Returns',
                value: '${isPositive ? "+" : ""}₹${_compactNum(totalPL.abs())}',
                valueColor: isPositive
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // PREFERENCES SECTION
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildPreferencesSection() {
    return Obx(() {
      final currency = _settingsController.currency.value;
      final notifs = _settingsController.notificationsEnabled.value;
      final dark = _themeController.isDarkMode;

      return _buildSection(
        label: 'PREFERENCES',
        rows: [
          _SettingRow(
            icon: Icons.language_rounded,
            label: 'Currency',
            subtitle: currency == 'USD' ? 'US Dollar (\$)' : 'Indian Rupee (₹)',
            accentColor: const Color(0xFF10B981),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                currency,
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            onTap: () => _settingsController.setCurrency(
              currency == 'USD' ? 'INR' : 'USD',
            ),
          ),
          _SettingRow(
            icon: Icons.dark_mode_outlined,
            label: 'Dark Mode',
            subtitle: dark ? 'Enabled' : 'Disabled',
            accentColor: const Color(0xFF6366F1),
            isToggle: true,
            toggled: dark,
            onToggle: () => _themeController.toggleDarkMode(!dark),
          ),
          _SettingRow(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            subtitle: notifs ? 'Price alerts & news' : 'Off',
            accentColor: const Color(0xFFF59E0B),
            isToggle: true,
            toggled: notifs,
            onToggle: () =>
                _settingsController.setNotificationsEnabled(!notifs),
          ),
          _SettingRow(
            icon: Icons.fingerprint_rounded,
            label: 'Biometric Login',
            subtitle: 'Fingerprint & Face ID',
            accentColor: const Color(0xFF8B5CF6),
            isToggle: true,
            toggled: _biometric,
            onToggle: () => setState(() => _biometric = !_biometric),
          ),
        ],
      );
    });
  }

  // ════════════════════════════════════════════════════════════════════════
  // DATA SECTION
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildDataSection() {
    return _buildSection(
      label: 'DATA & STORAGE',
      rows: [
        _SettingRow(
          icon: Icons.storage_outlined,
          label: 'Clear Cache',
          subtitle: 'Remove locally cached market data',
          accentColor: const Color(0xFF06B6D4),
          onTap: () async {
            await _settingsController.clearCache();
            if (!mounted) return;
            _showSnack('Cache cleared', 'Local market data removed',
                const Color(0xFF06B6D4));
          },
        ),
        _SettingRow(
          icon: Icons.download_outlined,
          label: 'Export Portfolio',
          subtitle: 'Download as CSV',
          accentColor: const Color(0xFF10B981),
          onTap: () => _showSnack(
              'Coming soon', 'CSV export feature in development',
              const Color(0xFF10B981)),
        ),
        _SettingRow(
          icon: Icons.cloud_sync_outlined,
          label: 'Backup & Sync',
          subtitle: 'Auto-sync to cloud',
          accentColor: const Color(0xFF818CF8),
          onTap: () => _showSnack(
              'Coming soon', 'Cloud backup in development',
              const Color(0xFF818CF8)),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // ABOUT SECTION
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildAboutSection() {
    return _buildSection(
      label: 'SUPPORT & ABOUT',
      rows: [
        _SettingRow(
          icon: Icons.star_outline_rounded,
          label: 'Rate InvestIQ',
          subtitle: 'Share your feedback',
          accentColor: const Color(0xFFF59E0B),
          onTap: () => _showSnack(
              'Thanks!', 'Rating feature coming soon',
              const Color(0xFFF59E0B)),
        ),
        _SettingRow(
          icon: Icons.help_outline_rounded,
          label: 'Help & Support',
          subtitle: 'FAQs and contact us',
          accentColor: const Color(0xFF818CF8),
        ),
        _SettingRow(
          icon: Icons.shield_outlined,
          label: 'Privacy Policy',
          accentColor: const Color(0xFF10B981),
        ),
        _SettingRow(
          icon: Icons.description_outlined,
          label: 'Terms of Service',
          accentColor: const Color(0xFF94A3B8),
        ),
        _SettingRow(
          icon: Icons.info_outline_rounded,
          label: 'App Version',
          subtitle: 'v1.0.0 · Build 100',
          accentColor: const Color(0xFF64748B),
          showChevron: false,
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // SIGN OUT
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildSignOutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _confirmSignOut,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.25),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: Color(0xFFEF4444),
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

  // ════════════════════════════════════════════════════════════════════════
  // REUSABLE: SECTION
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildSection({
    required String label,
    required List<_SettingRow> rows,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: rows.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                final isLast = i == rows.length - 1;

                return Column(
                  children: [
                    _buildSettingRow(row, isFirst: i == 0, isLast: isLast),
                    if (!isLast)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.only(left: 64),
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
      _SettingRow row, {
        bool isFirst = false,
        bool isLast = false,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: row.isToggle ? row.onToggle : row.onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(18) : Radius.zero,
          bottom: isLast ? const Radius.circular(18) : Radius.zero,
        ),
        splashColor: row.accentColor.withValues(alpha: 0.05),
        highlightColor: row.accentColor.withValues(alpha: 0.05),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: row.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: row.accentColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  row.icon,
                  size: 17,
                  color: row.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.label,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (row.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        row.subtitle!,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (row.trailing != null)
                row.trailing!
              else if (row.isToggle)
                _AnimatedToggle(
                  value: row.toggled ?? false,
                  onChanged: row.onToggle ?? () {},
                )
              else if (row.showChevron)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // BOTTOM SHEETS / DIALOGS
  // ════════════════════════════════════════════════════════════════════════

  void _showEditProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        decoration: const BoxDecoration(
          color: Color(0xFF131D2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Edit Profile',
              style: TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Profile editing coming soon',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'Got it',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF131D2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign Out?',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'You will need to sign in again to access your portfolio',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Sign Out',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await _auth.logout();
    }
  }

  void _showSnack(String title, String message, Color color) {
    Get.snackbar(
      title,
      message,
      backgroundColor: const Color(0xFF131D2E),
      colorText: const Color(0xFFF1F5F9),
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: Icon(Icons.info_outline_rounded, color: color, size: 20),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════════════════

  static String _formatJoinDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static String _compactNum(double v) {
    if (v >= 10000000) {
      return '${(v / 10000000).toStringAsFixed(1)}Cr';
    }
    if (v >= 100000) {
      return '${(v / 100000).toStringAsFixed(1)}L';
    }
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}K';
    }
    return v.toStringAsFixed(0);
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SETTING ROW MODEL
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _SettingRow {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color accentColor;
  final bool isToggle;
  final bool? toggled;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;

  const _SettingRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.accentColor,
    this.isToggle = false,
    this.toggled,
    this.onToggle,
    this.onTap,
    this.trailing,
    this.showChevron = true,
  });
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// QUICK STAT CARD
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFFF1F5F9),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ANIMATED TOGGLE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _AnimatedToggle extends StatefulWidget {
  final bool value;
  final VoidCallback onChanged;

  const _AnimatedToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_AnimatedToggle> createState() => _AnimatedToggleState();
}

class _AnimatedToggleState extends State<_AnimatedToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: widget.value ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      widget.value ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onChanged,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46,
        height: 26,
        decoration: BoxDecoration(
          gradient: widget.value
              ? const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          )
              : null,
          color: widget.value ? null : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: widget.value
                ? const Color(0xFF6366F1)
                : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: widget.value
              ? [
            BoxShadow(
              color:
              const Color(0xFF6366F1).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              left: widget.value ? 22 : 2,
              top: 2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}