import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pe/core/utils/logging/logger.dart';
import 'package:signature/signature.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pe/features/editor/controller/editor_controller.dart';
import '../../model/draggable_field.dart';
import '../widgets/dragable_text_field.dart';

class DocumentEditorScreen extends StatelessWidget {
  const DocumentEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EditorController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit'),
        actions: [
          IconButton(
            onPressed: () {
              controller.addTextBox();
            },
            icon: Icon(Icons.text_fields_rounded),
          ),
        ],
      ),
      body: Obx(() {
        return Stack(
          children: [
            SfPdfViewer.file(
              File(controller.currentFilePath.value),
              key: ValueKey(controller.documentVersion.value),
              pageLayoutMode: PdfPageLayoutMode.single,
              onDocumentLoaded: (details) {
                controller.onDocumentLoaded(details);
              },
            ),

            Center(
              child: Container(
                height: controller.pdfPageHeight.value * 0.67,
                width: double.maxFinite,
                color: Colors.red.withOpacity(0.1),
                child: Stack(
                  children: controller.textDraggableFields.asMap().entries.map((entry) {
                    int index = entry.key;
                    var field = entry.value;

                    return DraggableTextField(
                      index: index,
                      field: field,
                      onDrag: (idx, dx, dy) => controller.updateFieldPosition(idx, dx, dy),
                      onDelete: () => controller.textDraggableFields.removeAt(index),
                      onTextUpdate: (idx, newText) => controller.updateFieldText(idx, newText),
                      onSubmit: () {
                        controller.docChange(controller.outerDetails, field['x'], field['y'], field['text']);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
