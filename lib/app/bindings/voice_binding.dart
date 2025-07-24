// lib/app/bindings/voice_binding.dart
import 'package:get/get.dart';

import '../controllers/voice_controller.dart';
import '../services/voice_service.dart';

class VoiceBinding extends Bindings {
  @override
  void dependencies() {
    // Register VoiceService first (if not already registered)
    if (!Get.isRegistered<VoiceService>()) {
      Get.lazyPut<VoiceService>(() => VoiceService());
    }

    // Register VoiceController
    Get.lazyPut<VoiceController>(() => VoiceController());
  }
}