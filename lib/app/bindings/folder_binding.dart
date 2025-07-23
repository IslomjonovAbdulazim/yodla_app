import 'package:get/get.dart';
import '../controllers/folder_controller.dart';

class FolderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FolderController>(() => FolderController());
  }
}