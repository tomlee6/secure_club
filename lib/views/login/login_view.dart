import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/permission_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService.checkAndRequestCameraPermission(context);
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authConfig = context.watch<AuthProvider>();

    if (authConfig.isInit) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    if (authConfig.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/dashboard');
      });
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "SECURE CLUB",
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Guard Portal",
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 48),
                    CustomTextField(
                      label: "Email",
                      hintText: "mike.w@scantek.com",
                      controller: emailController,
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      label: "Password",
                      hintText: "••••••••",
                      obscureText: true,
                      controller: passwordController,
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: "LOGIN",
                      icon: Icons.login,
                      isLoading: authConfig.isLoading,
                      onPressed: () async {
                        if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter both email and password.')),
                          );
                          return;
                        }

                        final result = await context.read<AuthProvider>().login(
                          emailController.text.trim(),
                          passwordController.text.trim(),
                          "A1B2C3D4-E5F6-7890"
                        );

                        if (result['success'] == true && context.mounted) {
                          context.go('/dashboard');
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.errorRed,
                              content: Text(result['message'] ?? 'Login failed.')
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text(
                        "Forgot password?",
                        style: TextStyle(
                          color: AppColors.actionBlue,
                          fontWeight: FontWeight.w500,
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
    );
  }
}
