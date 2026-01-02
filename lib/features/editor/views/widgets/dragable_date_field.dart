import 'package:flutter/material.dart';

class DragableDateField extends StatelessWidget {
  final int index;
  final Map<String, dynamic> field;
  final Function(int, double, double) onDrag;
  final VoidCallback onDelete;
  final VoidCallback? onSubmit;
  final Function(int, String) onDateUpdate;

  const DragableDateField({
    super.key,
    required this.index,
    required this.field,
    required this.onDrag,
    required this.onDelete,
    required this.onDateUpdate,
    this.onSubmit,
  });

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      String formattedDate = "${picked.day}/${picked.month}/${picked.year}";
      onDateUpdate(index, formattedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: field['x'],
      top: field['y'],
      child: GestureDetector(
        onPanUpdate: (details) =>
            onDrag(index, details.delta.dx, details.delta.dy),
        onTap: () => _selectDate(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.orange, width: 1.5),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    field['text'],
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
              right: 15,
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
}
