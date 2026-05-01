import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_theme.dart';
import '../utils/safe_ui.dart';
import '../widgets/patterns_painter.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isHotReloading = false;

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final authService = context.read<AuthService>();
      final loggedIn = await authService.isLoggedIn();
      if (mounted) {
        SafeUI.navigate(context, (ctx) {
          if (mounted) {
            Navigator.of(ctx).pushReplacementNamed(loggedIn ? '/home' : '/login');
          }
        });
      }
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isHotReloading = true);
      });
      
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isHotReloading = false);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundWrapper(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/logo.png',
                width: 180,
                height: 180,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'T.',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.primary,
                      fontSize: 48,
                    ),
                  ),
                  Text(
                    'Speak',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 48,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Fait pour l\'Afrique ',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 48),
              // Custom Progress Bar
              SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  value: _isHotReloading ? 0.5 : null,
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 6,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 48.0),
                child: Text(
                  'LINGUISTIC HERITAGE x ARTIFICIAL INTELLIGENCE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 2,
                    color: AppColors.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
