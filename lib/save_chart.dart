import 'dart:ui' as ui;
import 'package:biz_trak_utility/utility.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'dart:html' as html;

class PieChartScreen extends StatefulWidget {
  @override
  _PieChartScreenState createState() => _PieChartScreenState();
}

class _PieChartScreenState extends State<PieChartScreen> with SingleTickerProviderStateMixin {
  List<Item> filteredItems = [];
  late AnimationController _controller;
  late Animation<double> _animation;
  final GlobalKey _globalKey = GlobalKey();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..addListener(() {
      setState(() {});
    });
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    filteredItems = List.from(items);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleItemSelection(Item item) {
    setState(() {
      item.isSelected = !item.isSelected;
      _controller.reset();
      _controller.forward();
    });
  }

  Future<void> _captureAndSaveChart() async {
    try {
      final boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);

      // Create a new image with the desired background color
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = Colors.grey[200]!;
      final size = Size(image.width.toDouble(), image.height.toDouble());
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      canvas.drawImage(image, Offset.zero, Paint());
      final newImage = await recorder.endRecording().toImage(size.width.toInt(), size.height.toInt());

      final byteData = await newImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final blob = html.Blob([pngBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "chart.png")
        ..click();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chart saved as chart.png')),
      );
    } catch (e) {
      print('Error saving chart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving chart')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return // Generated code for this Container Widget...
      Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFFE9EFEE),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: Border.all(
              color: Color(0xFF6F7979),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(8, 16, 8, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("lskdj hgdf"
                    ),
                    Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          IconButton(
                            icon: _isSaving ? CircularProgressIndicator(color: Colors.white) : Icon(Icons.save),
                            onPressed: _isSaving ? null : _captureAndSaveChart,
                          ),
                          Icon(
                            Icons.settings_rounded,
                            color: Color(0xFF161D1D),
                            size: 20,
                          ),
                        ]
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(8, 8, 8, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFD5DBDB),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),

                ),
              ),
            ],
          ),
        ),
      )
    ;
  }
}

class PieChartPainter extends CustomPainter {
  final List<Item> items;
  final double animationValue;

  PieChartPainter(this.items, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    double total = items.fold(0, (sum, item) => sum + (item.isSelected ? item.sales : 0)).toDouble();
    if (total == 0) {
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.text = TextSpan(
        text: 'No data',
        style: TextStyle(color: Colors.grey, fontSize: 20),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2));
      return;
    }

    double startAngle = -pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.grey.shade300
      ..strokeWidth = 2.0;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final radius = min(size.width, size.height) / 2;

    canvas.drawCircle(Offset(radius, radius), radius, outlinePaint);

    final labelPositions = <Offset>[];

    for (var item in items) {
      if (!item.isSelected) continue;

      final sweepAngle = (item.sales / total) * 2 * pi * animationValue;
      paint.color = Colors.primaries[items.indexOf(item) % Colors.primaries.length];

      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      final middleAngle = startAngle + sweepAngle / 2;
      final isSmallSlice = sweepAngle < 0.2;
      final x = radius + radius * cos(middleAngle) * (isSmallSlice ? 1.1 : 0.7);
      final y = radius + radius * sin(middleAngle) * (isSmallSlice ? 1.1 : 0.7);

      final percent = (item.sales / total * 100).toStringAsFixed(1) + '%';

      Offset labelPosition = Offset(x, y);

      final rotationAngle = middleAngle + pi / 2;

      for (var pos in labelPositions) {
        if ((pos - labelPosition).distance < 20) {
          labelPosition = labelPosition.translate(0, 20);
        }
      }
      labelPositions.add(labelPosition);

      canvas.save();
      canvas.translate(labelPosition.dx, labelPosition.dy);
      canvas.rotate(rotationAngle);

      textPainter.text = TextSpan(
        text: percent,
        style: TextStyle(
          fontSize: 10,
          color: isSmallSlice ? Colors.black : Colors.white,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
