import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pe/core/utils/logging/logger.dart';
import 'package:signature/signature.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:uuid/uuid.dart';
import '../model/draggable_field.dart';

class EditorController extends GetxController {
  final PdfViewerController pdfViewerController = PdfViewerController();
  final SignatureController sigController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );

  final String fileName;
  final String filePath;
  var fields = <DraggableField>[].obs;
  var zoomLevel = 1.0.obs;
  var scrollOffset = Offset.zero.obs;

  EditorController()
      : fileName = Get.arguments?['name'] ?? '',
        filePath = Get.arguments?['path'] ?? '';

  void addField(String type) {
    final scroll = scrollOffset.value;
    final zoom = zoomLevel.value;
    final centerX = (scroll.dx + MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width / 2) / zoom;
    final centerY = (scroll.dy + MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.height / 3) / zoom;

    fields.add(DraggableField(
      id: const Uuid().v4(),
      type: type,
      dx: centerX,
      dy: centerY,
    ));
  }

  void updateZoom(double newZoom) {
    zoomLevel.value = newZoom;
  }

  void updateScroll(Offset offset) {
    scrollOffset.value = offset;
  }

  void updatePosition(String fieldId, double newDx, double newDy) {
    final index = fields.indexWhere((field) => field.id == fieldId);
    if (index != -1) {
      fields[index].dx = newDx;
      fields[index].dy = newDy;
      fields.refresh();
    }
  }

  Future<void> saveSignature(String fieldId) async {
    if (sigController.isNotEmpty) {
      final Uint8List? data = await sigController.toPngBytes();
      if (data != null) {
        final index = fields.indexWhere((field) => field.id == fieldId);
        if (index != -1) {
          fields[index].signatureBytes = data;
          fields.refresh();
        }
        sigController.clear();
      }
    }
  }

  void updateFieldData(String fieldId, String newData) {
    final index = fields.indexWhere((field) => field.id == fieldId);
    if (index != -1) {
      fields[index].data = newData;
      fields.refresh();
    }
  }

  void removeField(String id) {
    AppLoggerHelper.info('Removing field: $id');
    fields.removeWhere((field) => field.id == id);
  }

  Future<void> saveConfiguration() async {
    try {
      final data = fields.map((e) => e.toJson()).toList();
      await FirebaseFirestore.instance.collection('configs').add({
        'fileName': fileName,
        'fields': data,
        'timestamp': FieldValue.serverTimestamp(),
      });
      Get.snackbar("Success", "Configuration saved to Firebase");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  @override
  void onClose() {
    pdfViewerController.dispose();
    sigController.dispose();
    super.onClose();
  }
}