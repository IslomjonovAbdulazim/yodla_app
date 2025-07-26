// lib/app/bindings/splash_binding.dart
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/scan_service.dart';
import '../services/storage_service.dart';
import '../services/camera_service.dart';
import '../services/voice_stream_service.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Core services that are used throughout the app
    Get.lazyPut<StorageService>(() => StorageService());
    Get.lazyPut<ApiService>(() => ApiService());
    Get.lazyPut<AuthService>(() => AuthService());
    Get.lazyPut<CameraService>(() => CameraService()); // Global registration
    Get.lazyPut<VoiceStreamService>(() => VoiceStreamService()); // Add this

    // Controllers
    Get.lazyPut<AuthController>(() => AuthController());
    Get.put(ScanService());
  }
}