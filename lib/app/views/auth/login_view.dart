import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../controllers/auth_controller.dart';
import '../../utils/app_colors.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 60),

              // App Logo and Welcome
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.school_rounded,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),

              SizedBox(height: 32),

              Text(
                'Welcome to VocabMaster',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 12),

              Text(
                'Learn English vocabulary with AI-powered lessons and interactive quizzes',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 60),

              // Apple Sign In Button
              Obx(() {
                if (controller.isAppleSignInAvailable) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: SignInWithAppleButton(
                          onPressed: controller.isLoading
                              ? null
                              : () => controller.signInWithApple(),
                          style: SignInWithAppleButtonStyle.black,
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),

                      SizedBox(height: 24),

                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      SizedBox(height: 24),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
              Spacer(),

              // Terms and Privacy
              Text(
                'By signing in, you agree to our Terms of Service and Privacy Policy',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
