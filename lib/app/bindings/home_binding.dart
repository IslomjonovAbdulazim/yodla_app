// lib/app/bindings/home_binding.dart
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../controllers/voice_stream_controller.dart';
import '../services/voice_stream_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Register new VoiceStreamService first
    if (!Get.isRegistered<VoiceStreamService>()) {
      Get.lazyPut<VoiceStreamService>(() => VoiceStreamService());
    }

    // Register new VoiceStreamController for Speak tab
    if (!Get.isRegistered<VoiceStreamController>()) {
      Get.lazyPut<VoiceStreamController>(() => VoiceStreamController());
    }

    // Register HomeController
    Get.lazyPut<HomeController>(() => HomeController());
  }
}