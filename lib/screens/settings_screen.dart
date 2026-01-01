import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:gps_tracker_app/providers/theme_provider.dart';
import 'package:gps_tracker_app/providers/auth_provider.dart';
import 'package:gps_tracker_app/services/auth_services.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  
  bool _notifications = true;
  bool _locationTracking = true;
  bool _autoConnect = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.isGuest ? null : auth.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [AppColors.darkBackground, Color(0xFF1E293B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(theme, user),
              
              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        
                        // Appearance Section
                        _buildSectionTitle(theme, 'Tampilan'),
                        const SizedBox(height: AppSpacing.sm),
                        _buildThemeCard(context, theme, isDark),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Preferences Section
                        _buildSectionTitle(theme, 'Preferensi'),
                        const SizedBox(height: AppSpacing.sm),
                        _buildToggleCard(
                          theme: theme,
                          isDark: isDark,
                          icon: Icons.notifications_outlined,
                          title: 'Notifikasi',
                          subtitle: 'Terima notifikasi dari perangkat',
                          value: _notifications,
                          onChanged: (v) => setState(() => _notifications = v),
                          activeColor: AppColors.primary,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildToggleCard(
                          theme: theme,
                          isDark: isDark,
                          icon: Icons.location_on_outlined,
                          title: 'Lacak Lokasi',
                          subtitle: 'Lacak lokasi secara otomatis',
                          value: _locationTracking,
                          onChanged: (v) => setState(() => _locationTracking = v),
                          activeColor: AppColors.secondary,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildToggleCard(
                          theme: theme,
                          isDark: isDark,
                          icon: Icons.bluetooth_connected_outlined,
                          title: 'Auto Connect',
                          subtitle: 'Terhubung ke perangkat terakhir',
                          value: _autoConnect,
                          onChanged: (v) => setState(() => _autoConnect = v),
                          activeColor: AppColors.accent,
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Account Section
                        _buildSectionTitle(theme, 'Akun'),
                        const SizedBox(height: AppSpacing.sm),
                        _buildActionCard(
                          theme: theme,
                          isDark: isDark,
                          icon: Icons.person_outline,
                          title: 'Edit Profil',
                          subtitle: 'Ubah foto dan nama Anda',
                          onTap: () {},
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildActionCard(
                          theme: theme,
                          isDark: isDark,
                          icon: Icons.security_outlined,
                          title: 'Keamanan',
                          subtitle: 'Kelola kata sandi dan 2FA',
                          onTap: () {},
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildActionCard(
                          theme: theme,
                          isDark: isDark,
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privasi',
                          subtitle: 'Pengaturan privasi data',
                          onTap: () {},
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Support Section
                        _buildSectionTitle(theme, 'Bantuan'),
                        const SizedBox(height: AppSpacing.sm),
                        _buildActionCard(
                          theme: theme,
                          isDark: isDark,
                          icon: Icons.help_outline,
                          title: 'Pusat Bantuan',
                          subtitle: 'FAQ dan panduan pengguna',
                          onTap: () {},
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildActionCard(
                          theme: theme,
                          isDark: isDark,
                          icon: Icons.info_outline,
                          title: 'Tentang',
                          subtitle: 'Versi aplikasi 1.0.0',
                          onTap: () {},
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Logout Button
                        _buildLogoutButton(theme),
                        
                        const SizedBox(height: AppSpacing.xl),
                      ],
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

  Widget _buildHeader(ThemeData theme, User? user) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppBorderRadius.xl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Back button
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.sm),
            
            // Title
            Text(
              'Pengaturan',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.darkSurface : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: AppShadows.medium,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: const Icon(
                    Icons.brightness_6,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tema',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isDark ? 'Mode Gelap' : 'Mode Terang',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Theme options
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Row(
                  children: [
                    _buildThemeOption(
                      theme: theme,
                      icon: Icons.light_mode,
                      label: 'Terang',
                      isSelected: themeProvider.themeMode == ThemeMode.light,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _buildThemeOption(
                      theme: theme,
                      icon: Icons.dark_mode,
                      label: 'Gelap',
                      isSelected: themeProvider.themeMode == ThemeMode.dark,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _buildThemeOption(
                      theme: theme,
                      icon: Icons.brightness_auto,
                      label: 'Sistem',
                      isSelected: themeProvider.themeMode == ThemeMode.system,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: isSelected ? AppGradients.primary : null,
            color: isSelected ? null : (isDark ? AppColors.darkCard : AppColors.lightCard),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.darkSurface : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: AppShadows.medium,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: activeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Icon(
                icon,
                color: activeColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: () => onChanged(!value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 28,
                decoration: BoxDecoration(
                  gradient: value ? AppGradients.primary : null,
                  color: value ? null : (isDark ? AppColors.darkCard : AppColors.lightCard),
                  borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  border: Border.all(
                    color: value ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppBorderRadius.full),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(30),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
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

  Widget _buildActionCard({
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppGradients.darkSurface : null,
          color: isDark ? null : Colors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: AppShadows.medium,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.iconTheme.color?.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          if (auth.isGuest) {
            await auth.signOutGuest();
          } else {
            await AuthService().logout();
          }

          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (Route<dynamic> route) => false,
            );
          }
        },
        icon: const Icon(Icons.logout, size: 20),
        label: const Text(
          'Keluar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
        ),
      ),
    );
  }
}

