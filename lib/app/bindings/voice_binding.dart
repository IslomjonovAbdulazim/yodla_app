import 'package:get/get.dart';

class VoiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VoiceBinding>(() => VoiceBinding());
  }
}