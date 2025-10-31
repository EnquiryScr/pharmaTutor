import 'package:flutter/material.dart';
import '../../core/utils/base_view.dart';
import '../../core/widgets/base_widgets.dart';
import '../../core/utils/validators.dart';
import '../../core/navigation/app_router.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginPage extends BaseView<AuthViewModel> {
  const LoginPage({super.key});

  @override
  AuthViewModel createViewModel() {
    return serviceLocator<AuthViewModel>();
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return null; // No app bar for login
  }

  @override
  Widget buildView(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 60.h),
              
              // Welcome Text
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 8.h),
              
              Text(
                'Sign in to continue learning',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 48.h),
              
              // Login Form
              const _LoginForm(),
              
              SizedBox(height: 24.h),
              
              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => NavigationHelper.goToForgotPassword(),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.primary,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Social Login Options
              const _SocialLoginDivider(),
              
              SizedBox(height: 32.h),
              
              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account? ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => NavigationHelper.goToRegister(),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final viewModel = ref.watch(serviceLocator<AuthViewModel>());
        
        return Form(
          key: _formKey,
          child: Column(
            children: [
              // Email Field
              BaseInputField(
                label: 'Email Address',
                hint: 'Enter your email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
                validator: EmailValidator.validate,
              ),
              
              SizedBox(height: 20.h),
              
              // Password Field
              BaseInputField(
                label: 'Password',
                hint: 'Enter your password',
                controller: _passwordController,
                obscureText: _obscurePassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 32.h),
              
              // Login Button
              BaseButton(
                text: 'Sign In',
                onPressed: () => _handleLogin(),
                isLoading: viewModel.isLoading,
                width: double.infinity,
              ),
              
              // Error Message
              if (viewModel.hasError) ...[
                SizedBox(height: 16.h),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          viewModel.error ?? 'An error occurred',
                          style: const TextStyle(
                            color: Colors.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      // Navigate to viewModel for login logic
      NavigationHelper.showSnackBar(message: 'Login functionality to be implemented');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _SocialLoginDivider extends StatelessWidget {
  const _SocialLoginDivider();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.textMuted,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        
        SizedBox(height: 20.h),
        
        // Google Login Button
        BaseButton(
          text: 'Continue with Google',
          onPressed: () {
            NavigationHelper.showSnackBar(
              message: 'Google login to be implemented',
            );
          },
          type: ButtonType.outline,
          icon: Icons.g_mobiledata,
          width: double.infinity,
        ),
        
        SizedBox(height: 12.h),
        
        // Apple Login Button (iOS only)
        if (Theme.of(context).platform == TargetPlatform.iOS) ...[
          BaseButton(
            text: 'Continue with Apple',
            onPressed: () {
              NavigationHelper.showSnackBar(
                message: 'Apple login to be implemented',
              );
            },
            type: ButtonType.outline,
            icon: Icons.apple,
            width: double.infinity,
          ),
        ],
      ],
    );
  }
}

// Placeholder AuthViewModel
class AuthViewModel {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    _isLoading = false;
    
    // For demo purposes, navigate to home
    NavigationHelper.goToHome();
  }
}