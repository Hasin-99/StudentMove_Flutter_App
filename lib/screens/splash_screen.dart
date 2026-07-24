import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo_3d.dart';

/// Brand splash with 3D logo and atmospheric depth.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _hasNavigated = false;
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _navigateToNext();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted || _hasNavigated) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    final targetRoute = authProvider.isAuthenticated ? '/home' : '/signin';
    final nav = Navigator.of(context, rootNavigator: true);
    nav.pushNamedAndRemoveUntil(targetRoute, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Atmosphere3DBackdrop(
        child: SafeArea(
          child: SizedBox.expand(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _motion,
                      curve: Curves.easeOut,
                    ),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.86, end: 1).animate(
                        CurvedAnimation(
                          parent: _motion,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BrandLogo3D(size: 148, float: true),
                          const SizedBox(height: 22),
                          Text(
                            'StudentMove',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.syne(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Move through Dhaka with intent.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.brand,
                            backgroundColor:
                                AppColors.brand.withValues(alpha: 0.16),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Smart transport for Dhaka students',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 12,
                            color: AppColors.muted,
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
      ),
    );
  }
}
