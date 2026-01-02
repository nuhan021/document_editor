import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pe/core/common/styles/global_text_style.dart';
import 'package:pe/core/common/widgets/custom_button.dart';

import '../../controller/upload_controller.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final UploadController controller = Get.put(UploadController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload Document", style: getTextStyle(fontSize: 20.sp)),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() {
              if (controller.selectedFile.value == null) {
                return _buildUploadPlaceholder();
              } else {
                return _buildFilePreview();
              }
            }),
            40.verticalSpace,
            Obx(
              () => CustomButton(
                text: controller.selectedFile.value == null
                    ? 'Select Document'
                    : 'Proceed to Edit',
                onPressed: controller.selectedFile.value == null
                    ? () => controller.pickLocalFile()
                    : () => controller.proceedToEditor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      children: [
        Icon(Icons.cloud_upload_outlined, size: 100.sp, color: Colors.blue),
        20.verticalSpace,
        Text(
          "Select a PDF or DOCX file from your device",
          textAlign: TextAlign.center,
          style: getTextStyle(fontSize: 16.sp, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildFilePreview() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue),
      ),
      child: Row(
        children: [
          Icon(Icons.description, size: 40.sp, color: Colors.blue),
          15.horizontalSpace,
          Expanded(
            child: Text(
              controller.selectedFile.value!.path.split('/').last,
              style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => controller.selectedFile.value = null,
            icon: Icon(Icons.close, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
