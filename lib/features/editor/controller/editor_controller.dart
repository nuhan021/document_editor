import 'dart:io';
import 'dart:typed_data';
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

class EditorController extends GetxController {
  final PdfViewerController pdfViewerController = PdfViewerController();
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

  var textDraggableFields = <Map<String, dynamic>>[].obs;

  late PdfDocumentLoadedDetails outerDetails;


  @override
  void onInit() {
    super.onInit();
    currentFilePath.value = filePath;
  }

  void addTextBox() {
    textDraggableFields.add({
      'id': const Uuid().v4(),
      'text': 'Nuhan',
      'x': 50.0,
      'y': 50.0,
    });
  }

  void updateFieldText(int index, String newText) {
    textDraggableFields[index]['text'] = newText;
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

  void docChange(PdfDocumentLoadedDetails details, double screenX, double screenY, String text) async {

    double containerWidth = Get.width;
    double containerHeight = pdfPageHeight.value * 0.67;

    double scaleX = pdfPageWidth.value / containerWidth;
    double scaleY = pdfPageHeight.value / containerHeight;

    double finalPdfX = screenX * scaleX;
    double finalPdfY = screenY * scaleY;

    AppLoggerHelper.info("Converting Screen ($screenX, $screenY) to PDF ($finalPdfX, $finalPdfY)");

    final Uint8List docBytes = await File(filePath).readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: docBytes);

    document.pages[0].graphics.drawString(
      text,
      PdfStandardFont(PdfFontFamily.helvetica, 20),
      brush: PdfSolidBrush(PdfColor(255, 0, 0)),
      bounds: Rect.fromLTWH(finalPdfX, finalPdfY, 150, 40),
    );

    final List<int> bytes = await document.save();
    document.dispose();

    final tempDir = await getTemporaryDirectory();
    final newFile = File('${tempDir.path}/temp_edited.pdf');
    await newFile.writeAsBytes(bytes, flush: true);

    currentFilePath.value = newFile.path;
    documentVersion.value++;
  }


  @override
  void onClose() {
    pdfViewerController.dispose();
    sigController.dispose();
    super.onClose();
  }
}