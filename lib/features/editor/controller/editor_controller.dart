import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
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
  var zoomLevel = 1.0.obs;
  var scrollOffset = Offset.zero.obs;
  var currentPageIndex = 0.obs;
  double lastDetectedWidth = 411.42; // ডিফল্ট হিসেবে আপনার লগ থেকে পাওয়া মান
  double lastDetectedHeight = 683.42;
  // Screen viewport dimensions
  double viewportWidth = 411.42;
  double viewportHeight = 683.42;

  // 🔥 NEW: Store actual PDF page dimensions
  var pdfPageWidth = 0.0.obs;
  var pdfPageHeight = 0.0.obs;

  bool get hasFilledField => fields.any((f) => f.data != null || f.signatureBytes != null);
  bool get canAddNewField => fields.isEmpty || fields.every((f) => f.data != null || f.signatureBytes != null);

  @override
  void onInit() {
    super.onInit();
    currentFilePath.value = filePath;
  }

  void onDocumentLoaded(PdfDocumentLoadedDetails details) {
    final page = details.document.pages[0];

    // PDF Points (আপনার লগে যা আসছে: ৬১২ x ৭৯২)
    double ptWidth = page.size.width;
    double ptHeight = page.size.height;

    // পিক্সেল ক্যালকুলেশন (৯৬ DPI স্ট্যান্ডার্ড ধরে)
    double dpi = 96.0;
    double pixelWidth = (ptWidth / 72) * dpi;
    double pixelHeight = (ptHeight / 72) * dpi;

    pdfPageWidth.value = ptWidth;
    pdfPageHeight.value = ptHeight;

    print('📄 PDF Size (Points): $ptWidth x $ptHeight');
    print('🖼️ PDF Size (Pixels at 96 DPI): ${pixelWidth.round()} x ${pixelHeight.round()}');
    print('📱 Viewport Size: $viewportWidth x $viewportHeight');
  }



  void addField(String type) {
    if (!canAddNewField) {
      Get.snackbar(
        "Action Required",
        "Please fill the current field first.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // গুরুত্বপূর্ণ: বর্তমান যে পেজটি স্ক্রিনে আছে তার ইনডেক্স সেভ করা
    int currentActivePage = pdfViewerController.pageNumber - 1;

    fields.add(DraggableField(
      id: const Uuid().v4(),
      type: type,
      pageIndex: currentActivePage, // এটি নিশ্চিত করে ডাটা সঠিক পাতায় বসবে
      dx: 100.0,
      dy: 100.0,
    ));
  }

  void updateZoom(double newZoom) => zoomLevel.value = newZoom;
  void updateScroll(Offset offset) => scrollOffset.value = offset;

  void updatePosition(String id, double newDx, double newDy) {
    int index = fields.indexWhere((f) => f.id == id);
    if (index != -1) {
      fields[index].dx = newDx;
      fields[index].dy = newDy;
      fields.refresh();
    }
  }

  void updateFieldData(String id, String data) {
    int index = fields.indexWhere((f) => f.id == id);
    if (index != -1) {
      fields[index].data = data;
      fields.refresh();
    }
  }

  Future<void> saveSignature(String id) async {
    if (sigController.isNotEmpty) {
      final Uint8List? data = await sigController.toPngBytes();
      int index = fields.indexWhere((f) => f.id == id);
      if (index != -1 && data != null) {
        fields[index].signatureBytes = data;
        fields.refresh();
        sigController.clear();
      }
    }
  }

  void removeField(String id) {
    fields.removeWhere((f) => f.id == id);
  }

  void updateLayoutConstraints(double w, double h) {
    lastDetectedWidth = w;
    lastDetectedHeight = h;
  }

  Future<void> applyFieldToDocument() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final Uint8List docBytes = await File(currentFilePath.value).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: docBytes);

      for (var field in fields.where((f) => f.data != null || f.signatureBytes != null)) {
        final PdfPage page = document.pages[field.pageIndex];
        final PdfGraphics graphics = page.graphics;


        final pdfWidth = page.size.width;
        final pdfHeight = page.size.height;

        final viewWidth = lastDetectedWidth;
        final viewHeight = lastDetectedHeight;

        final scaleX = pdfWidth / viewWidth;
        final scaleY = pdfHeight / viewHeight;

        // সবচেয়ে গুরুত্বপূর্ণ লাইন ↓
        double pdfX = field.dx * scaleX;
        double pdfY = (viewHeight - field.dy) * scaleY;

        if (field.type == 'signature' && field.signatureBytes != null) {
          graphics.drawImage(
            PdfBitmap(field.signatureBytes!),
            Rect.fromLTWH(pdfX, pdfY, 100 * scaleX, 50 * scaleY),
          );
        } else {
          graphics.drawString(
            field.data!,
            PdfStandardFont(PdfFontFamily.helvetica, 14 * scaleY), // ফন্ট সাইজও স্কেল করা ভালো
            bounds: Rect.fromLTWH(pdfX, pdfY - 5 * scaleY, 220 * scaleX, 60 * scaleY),
          );
        }
      }

      // ফাইল সেভ এবং রিফ্রেশ লজিক
      final List<int> bytes = await document.save();
      document.dispose();

      final tempDir = await getTemporaryDirectory();
      final newFile = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await newFile.writeAsBytes(bytes);

      currentFilePath.value = newFile.path;
      documentVersion.value++;
      fields.clear();

      Get.back(); // ডায়ালগ বন্ধ
      Get.snackbar("Success", "Applied successfully!", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.back();
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red);
    }
  }

  Future<void> saveFileLocally() async {
    try {
      if (Platform.isAndroid) {
        if (!await Permission.manageExternalStorage.request().isGranted) {
          await Permission.storage.request();
        }
      }

      Directory? baseDir;
      if (Platform.isAndroid) {
        baseDir = Directory('/storage/emulated/0/Download');
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }

      final String folderPath = '${baseDir.path}/PDF Editor';
      final Directory dir = Directory(folderPath);
      if (!await dir.exists()) await dir.create(recursive: true);

      final String finalPath = '$folderPath/signed_${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await File(currentFilePath.value).copy(finalPath);

      Get.dialog(
        AlertDialog(
          title: const Text("Document Saved"),
          content: Text("Location: Downloads/PDF Editor\nFile: signed_$fileName"),
          actions: [
            TextButton(onPressed: () => Get.close(2), child: const Text("OK")),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar("Error", "Save failed: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  void onClose() {
    pdfViewerController.dispose();
    sigController.dispose();
    super.onClose();
  }
}