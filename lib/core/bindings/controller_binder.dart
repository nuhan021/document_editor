

import 'package:get/get.dart';
import 'package:pe/features/auth/controller/login_controller.dart';
import 'package:pe/features/auth/controller/sign_up_controller.dart';
import 'package:pe/features/auth/service/auth_service.dart';
import 'package:pe/features/home/controller/upload_controller.dart';
import 'package:pe/features/home/service/file_service.dart';

import '../../features/editor/controller/editor_controller.dart';

class ControllerBinder extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(
          () => AuthService(),
      fenix: true,
    );

    Get.lazyPut<FileService>(
          () => FileService(),
      fenix: true,
    );

    Get.lazyPut<LoginController>(
          () => LoginController(),
      fenix: true,
    );

    Get.lazyPut<SignupController>(
          () => SignupController(),
      fenix: true,
    );

    Get.lazyPut<UploadController>(
          () => UploadController(),
      fenix: true,
    );

    Get.lazyPut<EditorController>(
          () => EditorController(),
      fenix: true,
    );

  }
}