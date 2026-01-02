import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pe/core/common/styles/global_text_style.dart';
import 'package:pe/core/common/widgets/custom_button.dart';
import 'package:pe/core/common/widgets/custom_text_field.dart';
import 'package:pe/core/utils/constants/icon_path.dart';
import '../../controller/sign_up_controller.dart';

class SignupScreen extends StatelessWidget {
  SignupScreen({super.key});

  final SignupController controller = Get.put(SignupController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            60.verticalSpace,

            Image.asset(IconPath.logo, height: 100.h),

            30.verticalSpace,

            Text(
              'Create Account',
              style: getTextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            25.verticalSpace,

            CustomTextField(
              controller: controller.emailController,
              hintText: 'Email',
            ),

            10.verticalSpace,

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

            10.verticalSpace,

            Obx(
              () => CustomTextField(
                controller: controller.confirmPasswordController,
                hintText: "Confirm Password",
                obscureText: !controller.isPasswordVisible.value,
              ),
            ),

            25.verticalSpace,

            Obx(
              () => CustomButton(
                text: 'Sign Up',
                onPressed: () => controller.signup(),
                isLoading: controller.isLoading.value,
              ),
            ),

            20.verticalSpace,

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account? ",
                  style: getTextStyle(fontSize: 14.sp),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
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
