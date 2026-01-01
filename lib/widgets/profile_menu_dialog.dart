import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gps_tracker_app/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import '../utils/theme.dart';

class ProfileMenuDialog extends StatefulWidget {
  const ProfileMenuDialog({super.key});

  @override
  State<ProfileMenuDialog> createState() => _ProfileMenuDialogState();
}

class _ProfileMenuDialogState extends State<ProfileMenuDialog> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );
    
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.isGuest ? null : auth.user;

    return GestureDetector(
      onTap: () => _closeDialog(),
      child: Material(
        color: Colors.black54,
        child: AnimatedBuilder(
          animation: Listenable.merge([_slideController, _scaleController]),
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Backdrop with fade
                FadeTransition(
                  opacity: _slideController,
                  child: Container(color: Colors.transparent),
                ),
                // Dialog container
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(_slideAnimation),
                    child: _buildDialogContent(theme, isDark, user),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDialogContent(ThemeData theme, bool isDark, User? user) {
    return GestureDetector(
      onTap: () {}, // Prevent tap propagation
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface.withOpacity(0.95) : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          border: Border.all(
            color: isDark ? AppColors.darkBorder.withOpacity(0.5) : AppColors.lightBorder.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 20),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with user info
            _buildHeader(theme, user),
            
            // Menu items
            _buildMenuItems(theme),
            
            // Bottom decorative element
            _buildBottomDecoration(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, User? user) {
    final auth = Provider.of<AuthProvider>(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.xl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Avatar with glow
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withAlpha(50),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: user?.photoURL == null
                    ? Text(
                        (user?.displayName != null && user!.displayName!.isNotEmpty)
                            ? user.displayName!.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                            : (user?.email != null ? user!.email![0].toUpperCase() : (auth.isGuest ? 'G' : 'U')),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? (auth.isGuest ? 'Guest' : 'User'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? (auth.isGuest ? '' : ''),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Close button
            IconButton(
              onPressed: _closeDialog,
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems(ThemeData theme) {
    final menuItems = [
      _MenuItemData(
        icon: Icons.person_add_alt_1,
        text: 'Tambah Akun',
        onTap: () => _handleAction('add_account'),
        color: AppColors.primary,
      ),
      _MenuItemData(
        icon: Icons.settings,
        text: 'Pengaturan',
        onTap: () => _handleAction('settings'),
        color: AppColors.secondary,
      ),
      _MenuItemData(
        icon: Icons.help_outline,
        text: 'Bantuan',
        onTap: () => _handleAction('help'),
        color: AppColors.accent,
      ),
      _MenuItemData(
        icon: Icons.logout,
        text: 'Keluar',
        onTap: () => _handleAction('logout'),
        color: AppColors.error,
        isDestructive: true,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: menuItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildMenuItem(item, theme, index);
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItemData item, ThemeData theme, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          highlightColor: item.isDestructive 
              ? AppColors.error.withOpacity(0.1)
              : item.color.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                // Icon with background
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (item.isDestructive 
                        ? AppColors.error 
                        : item.color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: item.isDestructive 
                        ? AppColors.error 
                        : item.color,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    item.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: item.isDestructive 
                          ? AppColors.error 
                          : theme.textTheme.bodyLarge?.color,
                      fontWeight: item.isDestructive 
                          ? FontWeight.w600 
                          : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.iconTheme.color?.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomDecoration() {
    return Container(
      height: 6,
      width: 60,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
      ),
    );
  }

  void _closeDialog([String? result]) {
    _slideController.reverse().then((_) {
      if (mounted) Navigator.pop(context, result);
    });
  }

  void _handleAction(String action) {
    // Close the dialog and return the action as the pop result so the caller
    // can perform navigation immediately after the dialog is dismissed.
    _closeDialog(action);
  }


}

class _MenuItemData {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color color;
  final bool isDestructive;

  _MenuItemData({
    required this.icon,
    required this.text,
    required this.onTap,
    required this.color,
    this.isDestructive = false,
  });
}

