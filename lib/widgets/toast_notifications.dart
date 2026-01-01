import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Toast Notification Widget
/// ======================
/// Modern animated toast notifications with glassmorphism effect
/// Supports success, error, warning, and info variants
class ToastNotification {
  static void show({
    required BuildContext context,
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    
    late final OverlayEntry entry;
    
    entry = OverlayEntry(
      builder: (_) => _ToastOverlay(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          entry.remove();
        },
      ),
    );
    
    overlay.insert(entry);
  }
  
  static void success(BuildContext context, String message) {
    show(context: context, message: message, type: ToastType.success);
  }
  
  static void error(BuildContext context, String message) {
    show(context: context, message: message, type: ToastType.error);
  }
  
  static void warning(BuildContext context, String message) {
    show(context: context, message: message, type: ToastType.warning);
  }
  
  static void info(BuildContext context, String message) {
    show(context: context, message: message, type: ToastType.info);
  }
}

enum ToastType {
  success,
  error,
  warning,
  info,
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay> with TickerProviderStateMixin {
  late final AnimationController _slideController;
  late final AnimationController _fadeController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    
    _slideController.forward();
    
    Future.delayed(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (mounted) {
      _slideController.reverse().then((_) {
        _fadeController.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final (icon, color, gradient) = switch (widget.type) {
      ToastType.success => (
        Icons.check_circle,
        AppColors.success,
        AppGradients.secondary,
      ),
      ToastType.error => (
        Icons.error,
        AppColors.error,
        LinearGradient(
          colors: [AppColors.error, AppColors.error.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      ToastType.warning => (
        Icons.warning,
        AppColors.warning,
        const LinearGradient(
          colors: [AppColors.warning, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      ToastType.info => (
        Icons.info,
        AppColors.info,
        AppGradients.primary,
      ),
    };

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark ? AppGradients.darkSurface : null,
                color: isDark ? null : theme.cardColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(isDark ? 40 : 30),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        ),
                        child: Icon(icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Message
                      Expanded(
                        child: Text(
                          widget.message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white : null,
                          ),
                        ),
                      ),
                      // Close button
                      GestureDetector(
                        onTap: _dismiss,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: theme.iconTheme.color?.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated Counter Widget
/// ======================
/// Animated counter for statistics display
class AnimatedCounter extends StatefulWidget {
  final int value;
  final Duration duration;
  final TextStyle? style;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1000),
    this.style,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<int> _counterAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _counterAnimation = IntTween(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _counterAnimation,
      builder: (context, child) {
        return Text(
          _counterAnimation.value.toString(),
          style: widget.style,
        );
      },
    );
  }
}

/// Animated Statistics Card
/// =======================
/// Premium statistics card with glassmorphism and animations
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? unit;
  final IconData icon;
  final Color color;
  final Gradient? gradient;
  final bool isLoading;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    this.unit,
    required this.icon,
    required this.color,
    this.gradient,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(isDark ? 40 : 30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and title
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Value
            isLoading
                ? SizedBox(
                    height: 32,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      minHeight: 4,
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      if (unit != null) ...[
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            unit!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

