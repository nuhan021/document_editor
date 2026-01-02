import 'package:flutter/material.dart';

class DraggableTextField extends StatelessWidget {
  final int index;
  final Map<String, dynamic> field;
  final Function(int, double, double) onDrag;
  final VoidCallback onDelete;
  final VoidCallback? onSubmit;
  final Function(int, String) onTextUpdate;

  const DraggableTextField({
    super.key,
    required this.index,
    required this.field,
    required this.onDrag,
    required this.onDelete,
    required this.onTextUpdate,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: field['x'],
      top: field['y'],
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(index, details.delta.dx, details.delta.dy),
        onTap: () => _showEditBottomSheet(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue, width: 1.5),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                ],
              ),
              child: Text(
                field['text'],
                style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),


            Positioned(
              right: -10,
              top: -10,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),

            Positioned(
              right: 10,
              top: -10,
              child: GestureDetector(
                onTap: onSubmit,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBottomSheet(BuildContext context) {
    final TextEditingController textController = TextEditingController(text: field['text']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // কীবোর্ড আসলে যাতে উপরে ওঠে
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // কীবোর্ডের জন্য প্যাডিং
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Edit Text",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                onTextUpdate(index, textController.text);
                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


}