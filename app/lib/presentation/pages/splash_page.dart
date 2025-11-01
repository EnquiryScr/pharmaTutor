import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/base_view.dart';
import '../../core/widgets/base_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../core/extensions/ui_extensions.dart';
import '../../core/navigation/app_router.dart';
import '../../core/utils/service_locator.dart';
import '../viewmodels/splash_viewmodel.dart';

class SplashPage extends BaseView<SplashViewModel> {
  const SplashPage({super.key});

  @override
  SplashViewModel createViewModel() {
    return SplashViewModel();
  }

  @override
  Widget buildView(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.primary,
              Colors.primaryLight,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.school,
                size: 60.sp,
                color: Colors.primary,
              ),
            ),
            
            SizedBox(height: 32.h),
            
            // App Name
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            
            SizedBox(height: 8.h),
            
            // Tagline
            Text(
              'Learn. Grow. Succeed.',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w300,
              ),
            ),
            
            SizedBox(height: 80.h),
            
            // Loading Indicator
            final viewModel = SplashViewModel();
            
            if (viewModel.isLoading) {
              return CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              );
            }
            
            const SizedBox.shrink(),
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