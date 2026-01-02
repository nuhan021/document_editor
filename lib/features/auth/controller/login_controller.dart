import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pe/routes/app_routes.dart';
import '../service/auth_service.dart';

class LoginController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isLoading = false.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }




  void login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar("Error", "Fill essential fields");
      return;
    }

    isLoading.value = true;
    var result = await _authService.login(emailController.text.trim(), passwordController.text.trim());
    isLoading.value = false;

    if (result != null) {
      Get.offAllNamed(AppRoute.homeScreen);
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}