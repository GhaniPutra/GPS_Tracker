import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:provider/provider.dart';
import 'package:gps_tracker_app/providers/auth_provider.dart';
import '../services/auth_services.dart';
import '../utils/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _isLogin = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mohon isi email dan kata sandi'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService().loginEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (_emailController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty || 
        _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mohon lengkapi nama, email, dan kata sandi'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Create user directly via Firebase Auth
      final credential = await firebase_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Update Display Name immediately so user has a name in the app
      await credential.user?.updateDisplayName(_nameController.text.trim());
      await credential.user?.reload();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().loginGoogle();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
          ),
        );
      }
      if (mounted) _showErrorSnackbar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() => _isLoading = true);
    try {
      // Guest flow should NOT call FirebaseAuth. Persist guest status locally
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.signInGuest();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
          ),
        );
      }
      if (mounted) _showErrorSnackbar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
      ),
    );
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xl),
                
                // Back button & title
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // App logo with gradient
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                            boxShadow: AppShadows.glowPrimary,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 56,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Ngetces',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _isLogin ? 'Masuk untuk melanjutkan' : 'Buat akun baru',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Login form
                _buildLoginForm(theme, isDark),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Divider with "or"
                _buildDivider(theme, isDark),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Social buttons
                _buildSocialButtons(theme, isDark),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Sign up link
                _buildSignUpLink(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(ThemeData theme, bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: (theme.cardColor).withOpacity(0.7),
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            border: Border.all(
              color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Name field (Only for Register)
              if (!_isLogin) ...[
                _buildAnimatedTextField(
                  controller: _nameController,
                  label: 'Nama Lengkap',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Email field
              _buildAnimatedTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Password field
              _buildAnimatedTextField(
                controller: _passwordController,
                label: 'Kata Sandi',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              // Forgot password
              if (_isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Lupa kata sandi?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Login button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_isLogin ? _handleLogin : _handleRegister),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        final isDarkField = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDarkField ? const Color(0xFFE0E0E0) : null;
        final labelColor = isDarkField ? const Color(0xFFE0E0E0) : Colors.grey.shade500;
        final iconColor = isDarkField ? const Color(0xFFBFC7D6) : Colors.grey.shade500;

        return Focus(
          onFocusChange: (_) {
            setState(() {});
          },
          child: Builder(
            builder: (fieldContext) {
              final focused = Focus.of(fieldContext).hasFocus;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  color: isDarkField ? AppColors.darkSurface.withOpacity(0.9) : null,
                  gradient: isDarkField
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.5),
                            Colors.white.withOpacity(0.3),
                          ],
                        ),
                  // compute border and shadow based on focus for clarity
                  border: Border.all(
                    color: (focused ? AppColors.primary : (isDarkField ? AppColors.darkBorder : Colors.grey.shade300)),
                    width: focused ? 2.0 : 1.0,
                  ),
                  boxShadow: focused
                      ? AppShadows.glowPrimary
                      : [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
            child: TextField(
              controller: controller,
              obscureText: isPassword && !_passwordVisible,
              keyboardType: keyboardType,
              style: TextStyle(fontSize: 15, color: textColor),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: labelColor,
                  fontSize: 14,
                ),
                prefixIcon: Icon(icon, size: 22, color: iconColor),
                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(
                          _passwordVisible ? Icons.visibility_off : Icons.visibility,
                          size: 22,
                          color: iconColor,
                        ),
                        onPressed: () {
                          setState(() => _passwordVisible = !_passwordVisible);
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: BorderSide(color: isDarkField ? AppColors.darkBorder : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: BorderSide(color: isDarkField ? AppColors.darkBorder : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                hintStyle: TextStyle(color: isDarkField ? const Color(0xFFE0E0E0) : Colors.grey.shade500),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          );
          },
        ),
      );
      },
    );
  }

  Widget _buildDivider(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'atau',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Google button
        _buildSocialButton(
          theme: theme,
          isDark: isDark,
          icon: Icons.mail_outline,
          text: 'Lanjutkan dengan Google',
          color: const Color(0xFFDB4437),
          onPressed: _handleGoogleLogin,
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Apple button
        _buildSocialButton(
          theme: theme,
          isDark: isDark,
          icon: Icons.apple,
          text: 'Lanjutkan dengan Apple',
          color: Colors.black,
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.md),
        // Guest button (Masuk sebagai Tamu)
        _buildSocialButton(
          theme: theme,
          isDark: isDark,
          icon: Icons.person_outline,
          text: 'Masuk sebagai Tamu',
          color: AppColors.accent,
          onPressed: _isLoading ? null : () => _handleGuestLogin(),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required String text,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24, color: color),
        label: Text(
          text,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: theme.cardColor.withOpacity(0.5),
          side: BorderSide(color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? 'Belum punya akun? ' : 'Sudah punya akun? ',
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isLogin = !_isLogin;
              _fadeController.forward(from: 0.0); // Re-animate for nice effect
            });
          },
          child: Text(
            _isLogin ? 'Daftar' : 'Masuk',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

