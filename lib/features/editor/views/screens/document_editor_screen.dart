import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pe/core/utils/logging/logger.dart';
import 'package:signature/signature.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pe/features/editor/controller/editor_controller.dart';
import '../../model/draggable_field.dart';

class DocumentEditorScreen extends StatelessWidget {
  const DocumentEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EditorController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Document Editor"),
        actions: [
          Obx(() {
            if (controller.hasFilledField) {
              return ElevatedButton.icon(
                onPressed: () => controller.applyFieldToDocument(),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text("APPLY", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              );
            }
            return TextButton(
              onPressed: () => _showFinalSaveDialog(context),
              child: const Text("FINISH", style: TextStyle(color: Colors.blue)),
            );
          }),
        ],
      ),
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              controller.updateScroll(
                controller.pdfViewerController.scrollOffset,
              );
              return true;
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                // ✅ Dynamic height instead of fixed 411
                final double maxWidth = constraints.maxWidth;
                final double maxHeight = constraints.maxHeight;

                // 🔥 KEY FIX: Store actual render dimensions
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.updateLayoutConstraints(maxWidth, maxHeight);
                });

                return Stack(
                  children: [
                    // ১. পিডিএফ ভিউয়ার লেয়ার
                    Obx(() {
                      return SfPdfViewer.file(
                        File(controller.currentFilePath.value),
                        key: ValueKey(controller.documentVersion.value),
                        controller: controller.pdfViewerController,
                        pageLayoutMode: PdfPageLayoutMode.single,
                        onDocumentLoaded: (details) {
                          // 🔥 Get actual PDF page dimensions when loaded
                          controller.onDocumentLoaded(details);
                        },
                        onZoomLevelChanged: (details) =>
                            controller.updateZoom(details.newZoomLevel),
                      );
                    }),

                    // ২. ড্র্যাগেবল উইজেট লেয়ার
                    Obx(() {
                      final zoom = controller.zoomLevel.value;
                      final activePage =
                          controller.pdfViewerController.pageNumber - 1;

                      return Stack(
                        children: controller.fields.map((field) {
                          if (field.pageIndex != activePage)
                            return const SizedBox.shrink();

                          final isFilled =
                              field.data != null || field.signatureBytes != null;

                          return Positioned(
                            key: ValueKey(field.id),
                            left: field.dx,
                            top: field.dy,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                double newX = field.dx + details.delta.dx;
                                double newY = field.dy + details.delta.dy;

                                newX = newX.clamp(0.0, maxWidth - 80);
                                newY = newY.clamp(0.0, maxHeight - 40);

                                controller.updatePosition(field.id, newX, newY);
                              },
                              child: Transform.scale(
                                scale: zoom,
                                alignment: Alignment.topLeft,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isFilled
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isFilled
                                              ? Colors.green
                                              : Colors.red,
                                          width: 2,
                                        ),
                                      ),
                                      child: GestureDetector(
                                        onTap: () => _handleFieldTap(
                                          context,
                                          field.type,
                                          field.id,
                                        ),
                                        child: _buildFieldContent(field),
                                      ),
                                    ),
                                    Positioned(
                                      top: -15,
                                      right: -15,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildActionButton(
                                            icon: Icons.edit,
                                            color: Colors.blue,
                                            onTap: () => _handleFieldTap(
                                              context,
                                              field.type,
                                              field.id,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          _buildActionButton(
                                            icon: Icons.close,
                                            color: Colors.red,
                                            onTap: () =>
                                                controller.removeField(field.id),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Obx(
            () => BottomAppBar(
          child: controller.canAddNewField
              ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildToolButton('signature', Icons.edit),
              _buildToolButton('text', Icons.text_fields),
              _buildToolButton('date', Icons.calendar_today),
            ],
          )
              : Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              "Fill the current field and click APPLY to add more",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFinalSaveDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text("Save Document"),
        content: const Text("Save the final document to your device?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.find<EditorController>().saveFileLocally();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildFieldContent(DraggableField field) {
    if (field.type == 'signature' && field.signatureBytes != null) {
      return Image.memory(
        field.signatureBytes!,
        width: 100,
        height: 50,
        fit: BoxFit.contain,
      );
    }
    return Text(
      field.data ?? field.type.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    );
  }

  void _handleFieldTap(BuildContext context, String type, String fieldId) {
    final controller = Get.find<EditorController>();
    if (type == 'signature') {
      _showSignaturePad(controller, fieldId);
    } else if (type == 'text') {
      _showTextInput(controller, fieldId);
    } else if (type == 'date') {
      _showDatePicker(context, controller, fieldId);
    }
  }

  void _showSignaturePad(EditorController controller, String fieldId) {
    Get.dialog(
      AlertDialog(
        title: const Text("Draw Signature"),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Signature(
                  controller: controller.sigController,
                  height: 200,
                  width: 300,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => controller.sigController.clear(),
                    child: const Text(
                      "Clear",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      controller.saveSignature(fieldId);
                      Get.back();
                    },
                    child: const Text("Save"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTextInput(EditorController controller, String fieldId) {
    final textController = TextEditingController();
    Get.bottomSheet(
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: "Enter Text",
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (textController.text.isNotEmpty) {
                      controller.updateFieldData(fieldId, textController.text);
                      Get.back();
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker(
    BuildContext context,
    EditorController controller,
    String fieldId,
  ) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.updateFieldData(
        fieldId,
        picked.toIso8601String().split('T')[0],
      );
    }
  }

  Widget _buildToolButton(String type, IconData icon) {
    return TextButton.icon(
      onPressed: () => Get.find<EditorController>().addField(type),
      icon: Icon(icon),
      label: Text(type.capitalizeFirst!),
    );
  }
}
