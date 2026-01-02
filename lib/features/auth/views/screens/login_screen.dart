import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:pe/core/common/styles/global_text_style.dart';
import 'package:pe/core/common/widgets/custom_button.dart';
import 'package:pe/core/common/widgets/custom_text_field.dart';
import 'package:pe/core/utils/constants/colors.dart';
import 'package:pe/core/utils/constants/icon_path.dart';
import 'package:pe/features/auth/controller/login_controller.dart';
import 'package:pe/routes/app_routes.dart';

import '../../service/auth_service.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController controller = Get.find<LoginController>();
  final AuthService auth = Get.find<AuthService>();

  @override
  void initState() {
    super.initState();
    if (auth.firebaseUser.value == null) {
      return;
    } else {
      Get.offAllNamed(AppRoute.homeScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            80.verticalSpace,

            Image.asset(IconPath.logo, height: 120.h),

            40.verticalSpace,

            Text(
              'Login',
              style: getTextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            20.verticalSpace,

            CustomTextField(
              controller: controller.emailController,
              hintText: 'Email',
            ),

            10.verticalSpace,

            // password
            Obx(
              () => CustomTextField(
                controller: controller.passwordController,
                hintText: "Password",
                obscureText: !controller.isPasswordVisible.value,
                suffixIcon: IconButton(
                  onPressed: () => controller.togglePasswordVisibility(),
                  icon: Icon(
                    controller.isPasswordVisible.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            20.verticalSpace,

            Obx(() {
              return CustomButton(
                text: 'Login',
                onPressed: () => controller.login(),
                isLoading: controller.isLoading.value,
              );
            }),

            20.verticalSpace,

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account? ",
                  style: getTextStyle(fontSize: 14.sp),
                ),
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoute.signupScreen),
                  child: Text(
                    "Login",
                    style: getTextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ).paddingSymmetric(horizontal: 16.w),
      ),
    );
  }
}
