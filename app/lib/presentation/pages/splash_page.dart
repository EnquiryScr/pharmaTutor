import 'package:flutter/material.dart';
import '../../core/navigation/app_router.dart';
import '../../core/constants/colors.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primaryLight,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // App Name
            const Text(
              'TutorFlow',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Tagline
            const Text(
              'Learn. Grow. Succeed.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
            
            const SizedBox(height: 80),
            
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class SplashViewModel {
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  Future<void> init() async {
    // Simulate splash loading
    await Future.delayed(const Duration(seconds: 2));
    
    _isLoading = false;
    
    // Navigate to appropriate screen based on authentication status
    // This would typically check for stored authentication tokens
  }
}