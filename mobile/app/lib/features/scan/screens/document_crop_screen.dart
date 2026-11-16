import 'dart:io';
import 'dart:ui' as ui;

import 'package:document_scan/document_scan.dart';
import 'package:flutter/material.dart';

class DocumentCropScreen extends StatefulWidget {
  const DocumentCropScreen({
    super.key,
    required this.imagePath,
    required this.initialCorners,
  });

  final String imagePath;
  final DocumentCorners initialCorners;

  @override
  State<DocumentCropScreen> createState() => _DocumentCropScreenState();
}

class _DocumentCropScreenState extends State<DocumentCropScreen> {
  late DocumentCorners _corners;
  late Future<Size> _imageSizeFuture;

  Rect _imageRect = Rect.zero;
  int? _activeHandle;

  @override
  void initState() {
    super.initState();
    _corners = widget.initialCorners;
    _imageSizeFuture = _loadImageSize();
  }

  Future<Size> _loadImageSize() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    final size = Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );

    frame.image.dispose();
    codec.dispose();

    return size;
  }

  List<Offset> _getHandlePositions() {
    final points = _corners.toList();

    final normalized = <Offset>[
      Offset(points[0].x, points[0].y),
      Offset(points[1].x, points[1].y),
      Offset(points[2].x, points[2].y),
      Offset(points[3].x, points[3].y),
      Offset((points[0].x + points[1].x) / 2, (points[0].y + points[1].y) / 2),
      Offset((points[1].x + points[2].x) / 2, (points[1].y + points[2].y) / 2),
      Offset((points[2].x + points[3].x) / 2, (points[2].y + points[3].y) / 2),
      Offset((points[3].x + points[0].x) / 2, (points[3].y + points[0].y) / 2),
    ];

    return normalized.map((point) {
      return Offset(
        _imageRect.left + point.dx * _imageRect.width,
        _imageRect.top + point.dy * _imageRect.height,
      );
    }).toList();
  }

  void _startDragging(Offset position) {
    final handles = _getHandlePositions();

    int? nearest;
    double nearestDistance = 32;

    for (int i = 0; i < handles.length; i++) {
      final distance = (handles[i] - position).distance;

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = i;
      }
    }

    _activeHandle = nearest;
  }

  void _updateCorners(Offset position) {
    if (_activeHandle == null || _imageRect.isEmpty) return;

    final index = _activeHandle!;

    final dx = (position.dx - _imageRect.left) / _imageRect.width;
    final dy = (position.dy - _imageRect.top) / _imageRect.height;

    final target = Offset(dx.clamp(0.0, 1.0), dy.clamp(0.0, 1.0));

    final points = _corners.toList();

    final updated = points.map((p) => Offset(p.x, p.y)).toList();

    if (index < 4) {
      updated[index] = target;
    } else {
      final edges = <List<int>>[
        [0, 1],
        [1, 2],
        [2, 3],
        [3, 0],
      ];

      final first = edges[index - 4][0];
      final second = edges[index - 4][1];

      final midpoint = Offset(
        (updated[first].dx + updated[second].dx) / 2,
        (updated[first].dy + updated[second].dy) / 2,
      );

      final delta = target - midpoint;

      updated[first] = Offset(
        (updated[first].dx + delta.dx).clamp(0.0, 1.0),
        (updated[first].dy + delta.dy).clamp(0.0, 1.0),
      );

      updated[second] = Offset(
        (updated[second].dx + delta.dx).clamp(0.0, 1.0),
        (updated[second].dy + delta.dy).clamp(0.0, 1.0),
      );
    }

    setState(() {
      _corners = DocumentCorners(
        topLeft: (x: updated[0].dx, y: updated[0].dy),
        topRight: (x: updated[1].dx, y: updated[1].dy),
        bottomRight: (x: updated[2].dx, y: updated[2].dy),
        bottomLeft: (x: updated[3].dx, y: updated[3].dy),
        confidence: _corners.confidence,
      );
    });
  }

  void _resetCorners() {
    setState(() {
      _corners = widget.initialCorners;
    });
  }

  void _confirmCrop() {
    Navigator.pop(context, _corners);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Adjust Document'),
        actions: [
          IconButton(
            tooltip: 'Reset boundaries',
            onPressed: _resetCorners,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Size>(
        future: _imageSizeFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final canvasSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );

              final fitted = applyBoxFit(
                BoxFit.contain,
                snapshot.data!,
                canvasSize,
              );

              _imageRect = Alignment.center.inscribe(
                fitted.destination,
                Offset.zero & canvasSize,
              );

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  _startDragging(details.localPosition);
                },
                onPanUpdate: (details) {
                  _updateCorners(details.localPosition);
                },
                onPanEnd: (_) {
                  _activeHandle = null;
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CropOverlayPainter(
                          imageRect: _imageRect,
                          corners: _corners,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Drag the 8 handles to adjust document boundaries.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _confirmCrop,
                      icon: const Icon(Icons.check),
                      label: const Text('Crop & Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter({required this.imageRect, required this.corners});

  final Rect imageRect;
  final DocumentCorners corners;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageRect.isEmpty) return;

    final points = corners.toList().map((point) {
      return Offset(
        imageRect.left + point.x * imageRect.width,
        imageRect.top + point.y * imageRect.height,
      );
    }).toList();

    final polygon = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();

    final outsidePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.48)
      ..style = PaintingStyle.fill;

    final outsidePath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addPath(polygon, Offset.zero);

    canvas.drawPath(outsidePath, outsidePaint);

    final borderPaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(polygon, borderPaint);

    final handles = <Offset>[
      ...points,
      Offset(
        (points[0].dx + points[1].dx) / 2,
        (points[0].dy + points[1].dy) / 2,
      ),
      Offset(
        (points[1].dx + points[2].dx) / 2,
        (points[1].dy + points[2].dy) / 2,
      ),
      Offset(
        (points[2].dx + points[3].dx) / 2,
        (points[2].dy + points[3].dy) / 2,
      ),
      Offset(
        (points[3].dx + points[0].dx) / 2,
        (points[3].dy + points[0].dy) / 2,
      ),
    ];

    for (int i = 0; i < handles.length; i++) {
      final radius = i < 4 ? 9.0 : 6.0;

      canvas.drawCircle(handles[i], radius, Paint()..color = Colors.white);

      canvas.drawCircle(
        handles[i],
        radius,
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.corners != corners || oldDelegate.imageRect != imageRect;
  }
}
