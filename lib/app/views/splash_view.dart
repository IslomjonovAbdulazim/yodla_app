import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routes/app_routes.dart';
import '../services/auth_service.dart';

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
      backgroundColor: Color(0xFFFFFFFF),
      body: Center(
        child: Text(
          'YODLA',
          style: GoogleFonts.armata(
            fontSize: 50,
            fontWeight: FontWeight.w900,
            color: Color(0xFF7AB2D3),
          ),
        ),
      ),
    );
  }
}