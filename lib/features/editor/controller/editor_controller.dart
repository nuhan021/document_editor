import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pe/core/utils/logging/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signature/signature.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:uuid/uuid.dart';
import '../model/draggable_field.dart';
import '../service/document_service.dart';

class EditorController extends GetxController {
  final PdfViewerController pdfViewerController = PdfViewerController();
  final DocumentService _docService = Get.find<DocumentService>();
  final SignatureController sigController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );

  var fields = <DraggableField>[].obs;
  final String fileName = Get.arguments['name'] ?? "document.pdf";
  final String filePath = Get.arguments['path'] ?? "";

  var currentFilePath = ''.obs;
  var documentVersion = 0.obs;

  var pdfPageWidth = 0.0.obs;
  var pdfPageHeight = 0.0.obs;
  var pdfAspectRatio = 0.0.obs;

  var boxX = 0.0.obs;
  var boxY = 0.0.obs;

  var currentPageIndex = 0.obs;

  var textDraggableFields = <Map<String, dynamic>>[].obs;

  late PdfDocumentLoadedDetails outerDetails;

  @override
  void onInit() {
    super.onInit();
    currentFilePath.value = filePath;
  }

  void addTextBox() {
    bool hasEmptyTextField = textDraggableFields.any(
      (field) =>
          field['type'] == 'text' &&
          field['text'] == 'text' &&
          field['isVisible'] == true &&
          field['pageIndex'] == currentPageIndex.value,
    );

    if (hasEmptyTextField) {
      Get.snackbar(
        "Warning",
        "Please edit the existing text box on this page.",
      );
      return;
    }

    textDraggableFields.add({
      'id': const Uuid().v4(),
      'text': 'text',
      'signature': '',
      'x': 50.0,
      'y': 50.0,
      'isVisible': true,
      'type': 'text',
      'pageIndex': currentPageIndex.value,
    });
  }

  void addDateBox() {
    textDraggableFields.add({
      'id': const Uuid().v4(),
      'text':
          "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
      'signature': '',
      'x': 100.0,
      'y': 100.0,
      'isVisible': true,
      'type': 'date',
      'pageIndex': currentPageIndex.value,
    });
  }

  void addSignatureBox() {
    textDraggableFields.add({
      'id': const Uuid().v4(),
      'text': 'Tap to Sign',
      'signature': '',
      'x': 100.0,
      'y': 150.0,
      'isVisible': true,
      'type': 'signature',
      'pageIndex': currentPageIndex.value,
    });
  }

  void updateSignatureImage(int index, Uint8List bytes) {
    textDraggableFields[index]['signature'] = base64Encode(bytes);
    textDraggableFields[index]['text'] = '';
    textDraggableFields.refresh();
  }

  String exportFieldsToJson() {
    if (textDraggableFields.isEmpty) {
      Get.snackbar(
        "Empty",
        "Please add text, date or signature box first.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return "[]";
    }
    List<Map<String, dynamic>> exportData = textDraggableFields.map((field) {
      var fieldCopy = Map<String, dynamic>.from(field);
      fieldCopy['isVisible'] = true;

      if (fieldCopy['type'] == 'text') {
        fieldCopy['text'] = 'text';
      }

      if (fieldCopy['type'] == 'signature') {
        fieldCopy['signature'] = '';
      }

      return fieldCopy;
    }).toList();
    String jsonString = jsonEncode(exportData);
    return jsonString;
  }

  void updateFieldText(int index, String newText) {
    textDraggableFields[index]['text'] = newText;
    textDraggableFields.refresh();
  }

  void hideField(int index) {
    textDraggableFields[index]['isVisible'] = false;
    textDraggableFields.refresh();
  }

  void updateFieldPosition(int index, double dx, double dy) {
    var field = textDraggableFields[index];
    double newX = field['x'] + dx;
    double newY = field['y'] + dy;

    double containerWidth = Get.width;
    double containerHeight = pdfPageHeight.value * 0.67;

    textDraggableFields[index]['x'] = newX.clamp(0.0, containerWidth - 100);
    textDraggableFields[index]['y'] = newY.clamp(0.0, containerHeight - 40);

    textDraggableFields.refresh();
  }

  void updateBoxPosition(double dx, double dy) {
    const double boxSize = 40.0;
    double containerWidth = Get.width;
    double containerHeight = pdfPageHeight.value * 0.67;

    double newX = boxX.value + dx;
    double newY = boxY.value + dy;

    boxX.value = newX.clamp(0.0, containerWidth - boxSize);
    boxY.value = newY.clamp(0.0, containerHeight - boxSize);
  }

  void onDocumentLoaded(PdfDocumentLoadedDetails details) {
    outerDetails = details;
    final PdfPage page = details.document.pages[0];
    double width = page.size.width;
    double height = page.size.height;

    pdfPageWidth.value = width;
    pdfPageHeight.value = height;
    if (height != 0) {
      pdfAspectRatio.value = width / height;
    }

    AppLoggerHelper.info("PDF Original Width: $width");
    AppLoggerHelper.info("PDF Original Height: $height");
    AppLoggerHelper.info("PDF Aspect Ratio: ${pdfAspectRatio.value}");
  }

  void acceptChange() async {
    final emptyField = textDraggableFields.firstWhereOrNull(
      (field) =>
          field['type'] == 'text' &&
          field['text'] == 'text' &&
          field['isVisible'] == true,
    );

    if (emptyField != null) {
      int pageNum = (emptyField['pageIndex'] ?? 0) + 1;

      Get.snackbar(
        "Warning",
        "Please edit the existing text box on Page $pageNum",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }
    for (var field in textDraggableFields) {
      field['isVisible'] = false;
    }
    textDraggableFields.refresh();
    docChange();

    AppLoggerHelper.info("All changes accepted and fields hidden.");
  }

  void docChange() async {
    double containerWidth = Get.width;
    double containerHeight = pdfPageHeight.value * 0.67;

    double scaleX = pdfPageWidth.value / containerWidth;
    double scaleY = pdfPageHeight.value / containerHeight;

    final Uint8List docBytes = await File(filePath).readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: docBytes);

    for (var field in textDraggableFields) {
      if (field['isVisible'] == false) {
        double finalPdfX = field['x'] * scaleX;
        double finalPdfY = field['y'] * scaleY;
        int pageIdx = field['pageIndex'] ?? 0;

        if (field['type'] == 'signature' &&
            field['signature'] != null &&
            field['signature'].toString().isNotEmpty) {
          final Uint8List signatureBytes = base64Decode(
            field['signature'].toString(),
          );

          document.pages[pageIdx].graphics.drawImage(
            PdfBitmap(signatureBytes),
            Rect.fromLTWH(finalPdfX + 10, finalPdfY + 20, 100, 50),
          );
        } else {
          document.pages[pageIdx].graphics.drawString(
            field['text'],
            PdfStandardFont(PdfFontFamily.helvetica, 14),
            brush: PdfSolidBrush(PdfColor(0, 0, 0)),
            bounds: Rect.fromLTWH(finalPdfX + 10, finalPdfY + 20, 200, 50),
          );
        }
      }
    }

    final List<int> bytes = await document.save();
    document.dispose();

    final tempDir = await getTemporaryDirectory();
    final newFile = File('${tempDir.path}/temp_edited.pdf');
    await newFile.writeAsBytes(bytes, flush: true);

    currentFilePath.value = newFile.path;
    documentVersion.value++;
  }

  Future<void> saveAndDownloadFile() async {
    try {
      final List<int> bytes = await outerDetails.document.save();

      String fileName =
          "Edited_Doc_${DateTime.now().millisecondsSinceEpoch}.pdf";

      if (Platform.isAndroid) {
        try {
          String fullPath = "/storage/emulated/0/Download/$fileName";
          final file = File(fullPath);
          await file.writeAsBytes(bytes, flush: true);

          Get.snackbar(
            "Success",
            "File saved to Downloads folder",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (e) {
          await _saveViaFilePicker(bytes);
        }
      } else {
        final directory = await getApplicationDocumentsDirectory();
        String fullPath = "${directory.path}/$fileName";
        final file = File(fullPath);
        await file.writeAsBytes(bytes, flush: true);
        Get.snackbar("Success", "File saved successfully");
      }
    } catch (e) {
      AppLoggerHelper.error("Save Error: $e");
      Get.snackbar("Error", "Could not save file");
    }
  }

  Future<void> _saveViaFilePicker(List<int> bytes) async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save your PDF:',
      fileName: 'edited_document.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: Uint8List.fromList(bytes),
    );

    if (outputFile != null) {
      Get.snackbar("Saved", "File saved successfully!");
    }
  }

  void onPublishPressed() async {
    String json = exportFieldsToJson();
    if (json != "[]") {
      String? docId = await _docService.uploadConfiguration(
        json,
        "MyDocument.pdf",
      );

      if (docId != null) {
        print("Share this ID: $docId");
      }
    }
  }

  Future<void> importFromLink(String link) async {
    try {
      if (!link.contains("pe-app://config/")) {
        Get.snackbar("Error", "Invalid Link Format");
        return;
      }

      String docId = link.split('/').last;

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('document_configs')
          .doc(docId)
          .get();

      if (doc.exists) {
        List<dynamic> importedFields = doc.get('fields');

        textDraggableFields.clear();
        for (var fieldData in importedFields) {
          textDraggableFields.add(Map<String, dynamic>.from(fieldData));
        }

        textDraggableFields.refresh();
        Get.snackbar("Success", "Configuration imported successfully!");
      } else {
        Get.snackbar("Error", "Configuration not found on server.");
      }
    } catch (e) {
      Get.snackbar("Error", "Import failed: $e");
    }
  }

  @override
  void onClose() {
    pdfViewerController.dispose();
    sigController.dispose();
    super.onClose();
  }
}
