import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
          IconButton(
            onPressed: () => controller.saveConfiguration(),
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            controller.updateScroll(Offset(
              controller.pdfViewerController.scrollOffset.dx,
              notification.metrics.pixels,
            ));
          }
          return true;
        },
        child: Stack(
          children: [
            SfPdfViewer.file(
              File(controller.filePath),
              controller: controller.pdfViewerController,
              onZoomLevelChanged: (details) => controller.updateZoom(details.newZoomLevel),
            ),
            Positioned.fill(
              child: Obx(() {
                final zoom = controller.zoomLevel.value;
                final scroll = controller.scrollOffset.value;

                return Stack(
                  children: controller.fields.map((field) {
                    final left = (field.dx * zoom) - scroll.dx;
                    final top = (field.dy * zoom) - scroll.dy;

                    return Positioned(
                      key: ValueKey(field.id),
                      left: left,
                      top: top,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          final newDx = ((left + details.delta.dx) + scroll.dx) / zoom;
                          final newDy = ((top + details.delta.dy) + scroll.dy) / zoom;
                          controller.updatePosition(field.id, newDx, newDy);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue, width: 1),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: () => _handleFieldTap(context, field.type, field.id),
                                child: _buildFieldContent(field),
                              ),
                              Positioned(
                                top: -12,
                                right: -12,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildActionButton(
                                      icon: Icons.edit,
                                      color: Colors.green,
                                      onTap: () => _handleFieldTap(context, field.type, field.id),
                                    ),
                                    const SizedBox(width: 4),
                                    _buildActionButton(
                                      icon: Icons.close,
                                      color: Colors.red,
                                      onTap: () => controller.removeField(field.id),
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildToolButton('signature', Icons.edit),
            _buildToolButton('text', Icons.text_fields),
            _buildToolButton('date', Icons.calendar_today),
          ],
        ),
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
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildFieldContent(DraggableField field) {
    if (field.type == 'signature' && field.signatureBytes != null) {
      return Image.memory(
        field.signatureBytes!,
        width: 80,
        height: 40,
        fit: BoxFit.contain,
      );
    }
    return Text(
      field.data ?? field.type.toUpperCase(),
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
                    child: const Text("Clear", style: TextStyle(color: Colors.red)),
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
    Get.bottomSheet(
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Enter Text"),
              onSubmitted: (val) {
                controller.updateFieldData(fieldId, val);
                Get.back();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDatePicker(BuildContext context, EditorController controller, String fieldId) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.updateFieldData(fieldId, picked.toIso8601String().split('T')[0]);
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