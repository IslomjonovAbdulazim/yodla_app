import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    // Wait 2 seconds for splash effect
    await Future.delayed(Duration(seconds: 2));

    try {
      final authService = Get.find<AuthService>();

      // Initialize auth service first
      await authService.initializeAuth();

      final token = authService.currentToken;
      final user = authService.currentUser;

      print('🔑 Token: $token');
      print('👤 User: ${user?.email}');
      print('🔍 isLoggedIn: ${authService.isLoggedIn}');

      // Simple check: if we have both token and user data
      if (token != null && user != null) {
        print('✅ Going to home');
        Get.offAllNamed(AppRoutes.home);
      } else {
        print('❌ Going to login');
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      print('💥 Error: $e');
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.school_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 32),

            // App Name
            Text(
              'VocabMaster',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 60),

            // Loading
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}