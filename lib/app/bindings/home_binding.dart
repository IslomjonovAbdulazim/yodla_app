// lib/app/bindings/home_binding.dart
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../controllers/voice_controller.dart';
import '../services/voice_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Register VoiceService first
    if (!Get.isRegistered<VoiceService>()) {
      Get.lazyPut<VoiceService>(() => VoiceService());
    }

    // Register VoiceController for Speak tab
    if (!Get.isRegistered<VoiceController>()) {
      Get.lazyPut<VoiceController>(() => VoiceController());
    }

    // Register HomeController
    Get.lazyPut<HomeController>(() => HomeController());
  }
}