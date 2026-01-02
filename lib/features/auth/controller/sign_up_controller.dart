import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pe/features/auth/service/auth_service.dart';
import 'package:pe/routes/app_routes.dart';

class SignupController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  var isLoading = false.obs;
  var isPasswordVisible = false.obs;

  void togglePasswordVisibility() => isPasswordVisible.value = !isPasswordVisible.value;

  Future<void> signup() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar("Error", "Please fill in all fields", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar("Error", "Passwords do not match", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isLoading.value = true;

      final result = await _authService.signUp(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (result != null) {
        Get.snackbar("Success", "Account created successfully");
        Get.offAllNamed(AppRoute.homeScreen);
      }
    } catch (e) {
      Get.snackbar("Signup Failed", e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}