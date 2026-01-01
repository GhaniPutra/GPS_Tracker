import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gps_tracker_app/providers/auth_provider.dart';
import '../utils/theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      icon: Icons.location_on_rounded,
      title: 'Real-time Tracking',
      description: 'Pantau lokasi keluarga dan aset Anda secara real-time dengan akurasi tinggi',
      gradient: AppGradients.primary,
      accentColor: AppColors.primary,
    ),
    _OnboardingData(
      icon: Icons.history_rounded,
      title: 'Riwayat Perjalanan',
      description: 'Simpan dan putar kembali rute perjalanan kapan saja dengan mudah',
      gradient: AppGradients.secondary,
      accentColor: AppColors.secondary,
    ),
    _OnboardingData(
      icon: Icons.notifications_active_rounded,
      title: 'Notifikasi Cerdas',
      description: 'Dapatkan notifikasi instan saat perangkat memasuki atau meninggalkan zona',
      gradient: AppGradients.sunset,
      accentColor: AppColors.accent,
    ),
    _OnboardingData(
      icon: Icons.group_rounded,
      title: 'Kelola Grup',
      description: 'Kelola anggota keluarga atau tim dalam satu aplikasi yang intuitif',
      gradient: AppGradients.ocean,
      accentColor: AppColors.info,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _scaleController.reset();
    _scaleController.forward();
  }

  Future<void> _navigateToLogin() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.markWelcomeSeen();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Top bar - Skip button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo section
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                            boxShadow: AppShadows.glowPrimary,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Ngetces',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (_currentPage < _pages.length - 1)
                      TextButton(
                        onPressed: () async {
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          await auth.markWelcomeSeen();
                          if (mounted) Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text(
                          'Lewati',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingPage(
                      data: _pages[index],
                      index: index,
                      isActive: index == _currentPage,
                      scaleAnimation: _currentPage == index ? _scaleAnimation : null,
                    );
                  },
                ),
              ),

              // Bottom section - indicators & button
              _buildBottomSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: (theme.cardColor).withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.xl),
        ),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 10),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: _currentPage == index ? AppGradients.primary : null,
                    color: _currentPage == index
                        ? null
                        : (_currentPage > index
                            ? AppColors.primary.withOpacity(0.3)
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                    borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Next/Get Started button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _navigateToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: Text(
                _currentPage == _pages.length - 1 ? 'Mulai Sekarang' : 'Lanjutkan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;
  final Color accentColor;

  _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.accentColor,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final int index;
  final bool isActive;
  final Animation<double>? scaleAnimation;

  const _OnboardingPage({
    required this.data,
    required this.index,
    required this.isActive,
    this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon container
          AnimatedBuilder(
            animation: scaleAnimation ?? kAlwaysCompleteAnimation,
            builder: (context, child) {
              final scale = (scaleAnimation?.value ?? 1.0) + (isActive ? 0.05 : 0.0);
              return Transform.scale(
                scale: scale.clamp(0.8, 1.1),
                child: child,
              );
            },
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: data.gradient,
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: data.accentColor.withAlpha(60),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Icon(
                data.icon,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Title
          Text(
            data.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              data.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

