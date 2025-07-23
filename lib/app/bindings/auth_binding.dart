import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(() => AuthService());
    Get.lazyPut<ApiService>(() => ApiService());
    Get.lazyPut<AuthController>(() => AuthController());
  }
}