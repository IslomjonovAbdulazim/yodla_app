// lib/app/bindings/voice_binding.dart
import 'package:get/get.dart';

import '../controllers/voice_stream_controller.dart';
import '../services/voice_stream_service.dart';

class VoiceBinding extends Bindings {
  @override
  void dependencies() {
    // Register new VoiceStreamService
    if (!Get.isRegistered<VoiceStreamService>()) {
      Get.lazyPut<VoiceStreamService>(() => VoiceStreamService());
    }

    // Register new VoiceStreamController
    Get.lazyPut<VoiceStreamController>(() => VoiceStreamController());
  }
}