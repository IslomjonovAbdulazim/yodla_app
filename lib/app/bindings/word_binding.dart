// lib/app/bindings/word_binding.dart
import 'package:get/get.dart';
import 'package:yodla_app/app/services/camera_service.dart';
import '../controllers/word_controller.dart';

class WordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WordController>(() => WordController());

    // Only register CameraService if not already registered
    if (!Get.isRegistered<CameraService>()) {
      Get.lazyPut<CameraService>(() => CameraService());
    }
  }
}