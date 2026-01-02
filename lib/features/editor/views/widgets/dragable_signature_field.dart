import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:signature/signature.dart';
import '../../controller/editor_controller.dart';

class DraggableSignatureField extends StatelessWidget {
  final int index;
  final Map<String, dynamic> field;
  final Function(int, double, double) onDrag;
  final Function(int, Uint8List) onSignatureAdded;
  final VoidCallback onDelete;

  const DraggableSignatureField({
    super.key,
    required this.index,
    required this.field,
    required this.onDrag,
    required this.onSignatureAdded,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String signatureData = field['signature'] ?? '';
    final bool hasSignature = signatureData.isNotEmpty;

    return Positioned(
      left: field['x'],
      top: field['y'],
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(index, details.delta.dx, details.delta.dy),
        onTap: () => _showSignaturePad(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 120,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: !hasSignature
                  ? const Center(child: Text("Tap to Sign", style: TextStyle(fontSize: 12, color: Colors.grey)))
                  : Image.memory(
                base64Decode(signatureData),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: -10,
              top: -10,
              child: GestureDetector(
                onTap: onDelete,
                child: const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignaturePad(BuildContext context) {
    final controller = Get.find<EditorController>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 400,
        child: Column(
          children: [
            const Text("Draw Signature", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Signature(controller: controller.sigController, backgroundColor: Colors.white),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(onPressed: () => controller.sigController.clear(), child: const Text("Clear")),
                ElevatedButton(
                  onPressed: () async {
                    final bytes = await controller.sigController.toPngBytes();
                    if (bytes != null) {
                      onSignatureAdded(index, bytes);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}