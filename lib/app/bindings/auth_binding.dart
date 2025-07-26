import 'package:get/get.dart';
import 'package:yodla_app/app/controllers/voice_stream_controller.dart';
import '../controllers/auth_controller.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(() => AuthService());
    Get.lazyPut<AuthController>(() => AuthController());
  }
}