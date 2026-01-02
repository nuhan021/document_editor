import 'dart:io';
import 'package:get/get.dart';
import 'package:pe/routes/app_routes.dart';
import '../service/file_service.dart';

class UploadController extends GetxController {
  final FileService _fileService = Get.find<FileService>();
  var selectedFile = Rx<File?>(null);

  Future<void> pickLocalFile() async {
    File? file = await _fileService.pickDocument();
    if (file != null) {
      selectedFile.value = file;
    }
  }

  void proceedToEditor() {
    if (selectedFile.value != null) {
      Get.toNamed(AppRoute.editorScreen, arguments: {
        'path': selectedFile.value!.path,
        'name': selectedFile.value!.path.split('/').last,
      });
    }
  }
}