import 'dart:typed_data';

class DraggableField {
  final String id;
  final String type;
  double dx;
  double dy;
  String? data;
  double width;
  double height;
  Uint8List? signatureBytes;
  final int pageIndex;

  DraggableField({
    required this.id,
    required this.type,
    required this.pageIndex,
    this.dx = 50.0,
    this.dy = 50.0,
    this.width = 120.0,
    this.height = 40.0,
    this.data,
    this.signatureBytes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'x': dx,
    'y': dy,
    'width': width,
    'height': height,
    'data': data,
    'pageIndex': pageIndex,
  };
}