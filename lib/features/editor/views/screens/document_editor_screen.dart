import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pe/core/utils/logging/logger.dart';
import 'package:signature/signature.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pe/features/editor/controller/editor_controller.dart';
import '../../model/draggable_field.dart';
import '../widgets/dragable_date_field.dart';
import '../widgets/dragable_signature_field.dart';
import '../widgets/dragable_text_field.dart';

class DocumentEditorScreen extends StatelessWidget {
  const DocumentEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EditorController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              controller.addTextBox();
            },
            icon: Icon(Icons.text_fields_rounded),
          ),

          IconButton(
            onPressed: () {
              controller.addDateBox();
            },
            icon: Icon(Icons.date_range),
          ),

          IconButton(
            onPressed: () {
              controller.addSignatureBox();
            },
            icon: Icon(CupertinoIcons.signature),
          ),

          IconButton(
            onPressed: () {
              controller.acceptChange();
            },
            icon: Icon(Icons.check),
          ),

          IconButton(
            onPressed: () {
              AppLoggerHelper.info(controller.exportFieldsToJson().toString());
            },
            icon: Icon(Icons.import_export_outlined),
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
              onPageChanged: (PdfPageChangedDetails details) {
                controller.currentPageIndex.value = details.newPageNumber - 1;
              },
            ),

            Center(
              child: Container(
                height: controller.pdfPageHeight.value * 0.67,
                width: double.maxFinite,
                color: Colors.red.withOpacity(0.1),
                child: Stack(
                  children: controller.textDraggableFields
                      .asMap()
                      .entries
                      .where((entry) {
                        var field = entry.value;
                        return field['isVisible'] == true &&
                            field['pageIndex'] ==
                                controller.currentPageIndex.value;
                      })
                      .map((entry) {
                        int index = entry.key;
                        var field = entry.value;
                        if (field['type'] == 'date') {
                          return DragableDateField(
                            index: index,
                            field: field,
                            onDrag: (idx, dx, dy) =>
                                controller.updateFieldPosition(idx, dx, dy),
                            onDelete: () =>
                                controller.textDraggableFields.removeAt(index),
                            onDateUpdate: (idx, newDate) =>
                                controller.updateFieldText(idx, newDate),
                            onSubmit: () {
                              controller.docChange();
                              controller.hideField(index);
                            },
                          );
                        }

                        if (field['type'] == 'signature') {
                          return DraggableSignatureField(
                            index: index,
                            field: field,
                            onDrag: (idx, dx, dy) => controller.updateFieldPosition(idx, dx, dy),
                            onSignatureAdded: (idx, bytes) => controller.updateSignatureImage(idx, bytes),
                            onDelete: () => controller.textDraggableFields.removeAt(index),
                          );
                        }
                        return DraggableTextField(
                          index: index,
                          field: field,
                          onDrag: (idx, dx, dy) =>
                              controller.updateFieldPosition(idx, dx, dy),
                          onDelete: () =>
                              controller.textDraggableFields.removeAt(index),
                          onTextUpdate: (idx, newText) =>
                              controller.updateFieldText(idx, newText),
                          onSubmit: () {
                            if (field['text'] == 'text') {
                              Get.snackbar(
                                "Warning",
                                "Please edit the existing text box first.",
                                snackPosition: SnackPosition.TOP,
                                backgroundColor: Colors.orange.withOpacity(0.8),
                                colorText: Colors.white,
                              );
                              return;
                            }
                            controller.docChange();
                            controller.hideField(index);
                          },
                        );
                      })
                      .toList(),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
