import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/auth_controller.dart';
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

  AuthController get _auth => Get.find<AuthController>();
  ThemeController get _themeController => Get.find<ThemeController>();
  SettingsController get _settingsController => Get.find<SettingsController>();

  String get _displayName =>
      HiveService.savedName ??
      _auth.firebaseUser.value?.displayName ??
      _auth.firebaseUser.value?.email?.split('@').first ??
      'Investor';

  String get _userEmail =>
      HiveService.savedEmail ?? _auth.firebaseUser.value?.email ?? '';

  String get _initials {
    final parts = _displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'U';
  }

  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeIn,
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
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
    return Obx(() {
      final currency = _settingsController.currency.value;
      final notificationsEnabled =
          _settingsController.notificationsEnabled.value;
      final darkModeEnabled = _themeController.isDarkMode;

      return Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        body: SafeArea(
          child: FadeTransition(
            opacity: _entranceFade,
            child: SlideTransition(
              position: _entranceSlide,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            label: 'PREFERENCES',
                            rows: [
                              _SettingRow(
                                icon: Icons.language_rounded,
                                label: 'Currency',
                                subtitle: currency == 'USD'
                                    ? 'US Dollar (\$)'
                                    : 'Indian Rupee (₹)',
                                accentColor: const Color(0xFF10B981),
                                onTap: () => _settingsController.setCurrency(
                                  currency == 'USD' ? 'INR' : 'USD',
                                ),
                              ),
                              _SettingRow(
                                icon: Icons.dark_mode_outlined,
                                label: 'Dark Mode',
                                accentColor: const Color(0xFF6366F1),
                                isToggle: true,
                                toggled: darkModeEnabled,
                                onToggle: () => _themeController.toggleDarkMode(
                                  !darkModeEnabled,
                                ),
                              ),
                              _SettingRow(
                                icon: Icons.notifications_outlined,
                                label: 'Notifications',
                                subtitle: notificationsEnabled
                                    ? 'Price alerts & news'
                                    : 'Off',
                                accentColor: const Color(0xFFF59E0B),
                                isToggle: true,
                                toggled: notificationsEnabled,
                                onToggle: () => _settingsController
                                    .setNotificationsEnabled(
                                  !notificationsEnabled,
                                ),
                              ),
                              _SettingRow(
                                icon: Icons.fingerprint_rounded,
                                label: 'Biometric Login',
                                subtitle: 'Fingerprint & Face ID',
                                accentColor: const Color(0xFF8B5CF6),
                                isToggle: true,
                                toggled: _biometric,
                                onToggle: () =>
                                    setState(() => _biometric = !_biometric),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildSection(
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
                                  Get.snackbar(
                                    'Cache Cleared',
                                    'Local market cache has been removed.',
                                    backgroundColor: const Color(0xFF1E293B),
                                    colorText: const Color(0xFFF1F5F9),
                                  );
                                },
                              ),
                              const _SettingRow(
                                icon: Icons.download_outlined,
                                label: 'Export Portfolio',
                                subtitle: 'CSV export coming next',
                                accentColor: Color(0xFF10B981),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildSection(
                            label: 'ABOUT',
                            rows: const [
                              _SettingRow(
                                icon: Icons.star_outline_rounded,
                                label: 'Rate InvestIQ',
                                accentColor: Color(0xFFF59E0B),
                              ),
                              _SettingRow(
                                icon: Icons.help_outline_rounded,
                                label: 'Help & Support',
                                accentColor: Color(0xFF818CF8),
                              ),
                              _SettingRow(
                                icon: Icons.info_outline_rounded,
                                label: 'App Version',
                                subtitle: 'v1.0.0 · Build 100',
                                accentColor: Color(0xFF64748B),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildSignOutButton(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF130B2E), Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildUserCard(),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1A4F), Color(0xFF0F0D2E)],
        ),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
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
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName,
                          style: const TextStyle(
                            color: Color(0xFFF1F5F9),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _userEmail,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'Active Account',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
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
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.07),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statItem('Live', 'Sync'),
                  _statDivider(),
                  _statItem('Local', 'AI'),
                  _statDivider(),
                  _statItem('Cloud', 'Backup'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withOpacity(0.07),
    );
  }

  Widget _buildSection({
    required String label,
    required List<_SettingRow> rows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: rows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return Column(
                children: [
                  if (index > 0)
                    Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.04),
                    ),
                  _buildSettingRow(row),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow(_SettingRow row) {
    return GestureDetector(
      onTap: row.isToggle ? row.onToggle : row.onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: row.destructive
                    ? const Color(0xFFEF4444).withOpacity(0.12)
                    : row.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                row.icon,
                size: 16,
                color: row.destructive
                    ? const Color(0xFFEF4444)
                    : row.accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.label,
                    style: TextStyle(
                      color: row.destructive
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFE2E8F0),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (row.subtitle != null) ...[
                    const SizedBox(height: 1),
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
            if (row.isToggle)
              _AnimatedToggle(
                value: row.toggled ?? false,
                onChanged: row.onToggle ?? () {},
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: Color(0xFF475569),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return GestureDetector(
      onTap: () => Get.find<AuthController>().logout(),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
            SizedBox(width: 10),
            Text(
              'Sign Out',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color accentColor;
  final bool isToggle;
  final bool? toggled;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final bool destructive;

  const _SettingRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.accentColor,
    this.isToggle = false,
    this.toggled,
    this.onToggle,
    this.onTap,
    this.destructive = false,
  });
}

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
          color: widget.value
              ? const Color(0xFF6366F1)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: widget.value
                ? const Color(0xFF6366F1)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
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
                  color:
                      widget.value ? Colors.white : const Color(0xFF64748B),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
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
