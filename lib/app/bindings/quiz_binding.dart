import 'package:get/get.dart';
import 'package:yodla_app/app/controllers/quiz_controller.dart';

class QuizBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QuizController>(() => QuizController());

  }
}