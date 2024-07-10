import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

import 'utility.dart';



class SalesChart extends StatefulWidget {
  final List<SalesData> salesData;
  final ChartConfigStruct config;
  final CurrencyDataStruct currencyData;
  final double width;
  final double height;

  const SalesChart({
    Key? key,
    required this.salesData,
    required this.config,
    required this.currencyData,
    this.width = double.infinity,
    this.height = 450,
  }) : super(key: key);

  @override
  _SalesChartState createState() => _SalesChartState();
}

GlobalKey globalKey = GlobalKey();

class _SalesChartState extends State<SalesChart> with SingleTickerProviderStateMixin {
  final GlobalKey _paintKey = GlobalKey();
  Offset? _touchPoint;
  SalesData? _selectedData;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _captureAndSaveChart() async {
    try {
      final boundary = globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFE9EFEE),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: Color(0xFF6F7979),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(8.0, 16.0, 0.0, 0.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Daily"),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.save,
                                  color: Color(0xFF161D1D),
                                  size: 20.0,
                                ),
                                onPressed: _captureAndSaveChart,
                              ),
                              Icon(
                                Icons.settings_rounded,
                                color: Color(0xFF161D1D),
                                size: 20.0,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onPanDown: (details) {
                        _updateTouchPoint(details.localPosition, constraints.biggest);
                      },
                      onPanUpdate: (details) {
                        _updateTouchPoint(details.localPosition, constraints.biggest);
                      },
                      onPanEnd: (details) {
                        setState(() {
                          _touchPoint = null;
                          _selectedData = null;
                        });
                      },
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(8.0, 8.0, 8.0, 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFD5DBDB),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: RepaintBoundary(
                            key: globalKey,
                            child: Container(
                              width: widget.width,
                              height: widget.height,
                              child: CustomPaint(
                                key: _paintKey,
                                painter: SalesChartPainter(
                                  widget.salesData,
                                  config: widget.config,
                                  currencyData: widget.currencyData,
                                  touchPoint: _touchPoint,
                                  selectedData: _selectedData,
                                  animationValue: _animationController.value,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateTouchPoint(Offset localPosition, Size chartSize) {
    final double leftPadding = widget.config.showYAxis == true ? 50.0 : 8.0;
    final double rightPadding = 8.0;
    final double topPadding = 16.0;
    final double bottomPadding = 16.0;

    final double chartWidth = chartSize.width - leftPadding - rightPadding;
    final double chartHeight = chartSize.height - topPadding - bottomPadding;

    if (localPosition.dx >= leftPadding &&
        localPosition.dx <= chartSize.width - rightPadding &&
        localPosition.dy >= topPadding &&
        localPosition.dy <= chartSize.height - bottomPadding) {
      setState(() {
        _touchPoint = localPosition;
        _selectedData = _getSalesDataFromTouchPoint(localPosition, chartWidth);
      });
    }
  }

  SalesData? _getSalesDataFromTouchPoint(Offset touchPoint, double chartWidth) {
    final double stepWidth = chartWidth / (widget.salesData.length - 1);
    final double touchX = touchPoint.dx - (widget.config.showYAxis == true ? 50.0 : 8.0);

    int touchedIndex = (touchX / stepWidth).floor();
    if (touchedIndex >= 0 && touchedIndex < widget.salesData.length - 1) {
      final double midPointX = (touchedIndex + 0.5) * stepWidth;
      if (touchX > midPointX) {
        touchedIndex += 1;
      }
    }

    if (touchedIndex >= 0 && touchedIndex < widget.salesData.length) {
      return widget.salesData[touchedIndex];
    }
    return null;
  }
}

class SalesChartPainter extends CustomPainter {
  final List<SalesData> salesData;
  final ChartConfigStruct config;
  final CurrencyDataStruct currencyData;
  final Offset? touchPoint;
  final SalesData? selectedData;
  final double animationValue;

  SalesChartPainter(
      this.salesData, {
        required this.config,
        required this.currencyData,
        this.touchPoint,
        this.selectedData,
        required this.animationValue,
      });

  @override
  void paint(Canvas canvas, Size size) {
    final double leftPadding = config.showYAxis == true ? 50.0 : 16.0;
    final double rightPadding = 16.0;
    final double topPadding = 32.0;
    final double bottomPadding = 32.0;

    final paint = Paint()
      ..color = config.salesLineColor ?? const Color(0xff4259A4)
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    final double chartHeight = size.height - topPadding - bottomPadding;
    final double chartWidth = size.width - leftPadding - rightPadding;

    if (config.showGridLines == true) {
      _drawGridLines(canvas, size, chartWidth, chartHeight, leftPadding, rightPadding, topPadding, bottomPadding);
    }
    if (config.showLabels == true || config.showYAxis == true) {
      _drawAxes(canvas, size, chartWidth, chartHeight, leftPadding, rightPadding, topPadding, bottomPadding);
    }
    _drawSalesData(canvas, size, chartWidth, chartHeight, leftPadding, rightPadding, topPadding, bottomPadding);
    _drawDataPoints(canvas, chartWidth, chartHeight, leftPadding, rightPadding, topPadding, bottomPadding);

    if (touchPoint != null && selectedData != null) {
      _drawTooltip(canvas, size, chartWidth, chartHeight, leftPadding, rightPadding, topPadding, bottomPadding);
    }
  }

  void _drawGridLines(Canvas canvas, Size size, double chartWidth, double chartHeight, double leftPadding, double rightPadding, double topPadding, double bottomPadding) {
    final gridPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 0.5;

    const int horizontalLines = 5;

    for (int i = 0; i <= horizontalLines; i++) {
      final y = size.height - bottomPadding - (i * chartHeight / horizontalLines);
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }
  }

  void _drawAxes(Canvas canvas, Size size, double chartWidth, double chartHeight, double leftPadding, double rightPadding, double topPadding, double bottomPadding) {
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;

    // Draw X Axis line only if showLabels is true
    if (config.showLabels == true) {
      canvas.drawLine(
        Offset(leftPadding, size.height - bottomPadding),
        Offset(size.width - rightPadding, size.height - bottomPadding),
        axisPaint,
      );
    }

    // Draw Y Axis line only if showYAxis is true
    if (config.showYAxis == true) {
      canvas.drawLine(
        Offset(leftPadding, topPadding),
        Offset(leftPadding, size.height - bottomPadding),
        axisPaint,
      );
    }

    final textStyle = const TextStyle(color: Colors.black, fontSize: 9);
    final maxValue = salesData.map((data) => data.salesValue).reduce((a, b) => a! > b! ? a : b)! * 1.1;
    const minValue = 0;
    final step = (maxValue - minValue) / 5;

    if (config.showYAxis == true) {
      for (int i = 0; i <= 5; i++) {
        final y = size.height - bottomPadding - (i * chartHeight / 5);
        final value = minValue + (step * i);
        final label = formatCurrency(value, currencyData);
        final textPainter = TextPainter(
          text: TextSpan(text: label, style: textStyle),
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout(minWidth: 0, maxWidth: chartWidth);
        textPainter.paint(canvas, Offset(leftPadding - 45, y - 6)); // Adjust for increased padding
      }
    }

    if (config.showLabels == true) {
      for (int i = 0; i < salesData.length; i++) {
        if (i % (salesData.length ~/ 10 + 1) != 0) continue;

        final data = salesData[i];
        final x = leftPadding + i * (chartWidth / (salesData.length - 1));
        final label = DateFormat('MM/dd').format(data.date);
        final textPainter = TextPainter(
          text: TextSpan(text: label, style: textStyle.copyWith(fontSize: 8)), // Smaller font size
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout(minWidth: 0, maxWidth: chartWidth);

        canvas.save();
        canvas.translate(x, size.height - bottomPadding + 10);
        canvas.rotate(-45 * 3.1415927 / 180);
        textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
        canvas.restore();
      }
    }
  }

  void _drawSalesData(Canvas canvas, Size size, double chartWidth, double chartHeight, double leftPadding, double rightPadding, double topPadding, double bottomPadding) {
    final path = Path();
    final fillPath = Path();
    bool isFirstPoint = true;
    final double maxValue = salesData.map((data) => data.salesValue).reduce((a, b) => a! > b! ? a : b)! * 1.1;

    for (int i = 0; i < salesData.length; i++) {
      final data = salesData[i];
      final x = leftPadding + i * (chartWidth / (salesData.length - 1));
      final y = topPadding + (chartHeight - (data.salesValue! / maxValue) * chartHeight);

      if (isFirstPoint) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
        isFirstPoint = false;
      } else {
        final previousX = leftPadding + (i - 1) * (chartWidth / (salesData.length - 1));
        final previousY = topPadding + (chartHeight - (salesData[i - 1].salesValue! / maxValue) * chartHeight);
        final controlPointX1 = (previousX + x) / 2;
        final controlPointX2 = (previousX + x) / 2;
        path.cubicTo(controlPointX1, previousY, controlPointX2, y, x, y);
        fillPath.cubicTo(controlPointX1, previousY, controlPointX2, y, x, y);
      }
    }

    if (config.fillBelowLine == true) {
      fillPath.lineTo(size.width - rightPadding, size.height - bottomPadding);
      fillPath.lineTo(leftPadding, size.height - bottomPadding);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(leftPadding, topPadding),
          Offset(leftPadding, size.height - bottomPadding),
          [
            const Color(0xff74ebd5).withOpacity(0.3),
            const Color(0xffACB6E5).withOpacity(0.3)
          ],
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    final linePaint = Paint()
      ..color = config.salesLineColor ?? const Color(0xff4259A4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);
  }

  void _drawDataPoints(Canvas canvas, double chartWidth, double chartHeight, double leftPadding, double rightPadding, double topPadding, double bottomPadding) {
    final double maxValue = salesData.map((data) => data.salesValue).reduce((a, b) => a! > b! ? a : b)! * 1.1;
    final textStyle = TextStyle(color: Colors.black, fontSize: 10);

    for (int i = 0; i < salesData.length; i++) {
      final data = salesData[i];
      final x = leftPadding + i * (chartWidth / (salesData.length - 1));
      final y = topPadding + (chartHeight - (data.salesValue! / maxValue) * chartHeight);

      final pointPaint = Paint()
        ..color = const Color(0xff052ba4)
        ..style = PaintingStyle.fill;

      final outlinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(Offset(x, y), 4.0, outlinePaint);
      canvas.drawCircle(Offset(x, y), 4.0, pointPaint);

      if (config.showValues == true) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: AddThousandsSeparator(data.salesValue!.toStringAsFixed(0), currencyData.thousandsSeparator),
            style: textStyle,
          ),
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout(minWidth: 0, maxWidth: chartWidth);

        final textOffset = (i % 2 == 0)
            ? Offset(x - textPainter.width / 2, y - 20)
            : Offset(x - textPainter.width / 2, y + 8);

        textPainter.paint(canvas, textOffset);
      }
    }
  }

  void _drawTooltip(Canvas canvas, Size size, double chartWidth, double chartHeight, double leftPadding, double rightPadding, double topPadding, double bottomPadding) {
    final tooltipPaint = Paint()
      ..color = Colors.blueGrey[700]!.withOpacity(0.6)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1);

    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    final textSpan = TextSpan(
      text: selectedData != null ? formatCurrency(selectedData!.salesValue!, currencyData) : 'No Data',
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout(minWidth: 0, maxWidth: size.width);

    final tooltipHeight = 40.0;
    final tooltipWidth = textPainter.width + 16;
    final tooltipPosition = Offset(
      touchPoint!.dx - (tooltipWidth / 2),
      touchPoint!.dy - tooltipHeight - 10,
    );

    final rect = Rect.fromLTWH(
      tooltipPosition.dx,
      tooltipPosition.dy,
      tooltipWidth,
      tooltipHeight,
    );



    final verticalLinePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, 1);

    final path = Path();
    final dashWidth = 5;
    final dashSpace = 5;
    double startY = topPadding;
    while (startY < size.height - bottomPadding) {
      path.moveTo(touchPoint!.dx, startY);
      path.lineTo(touchPoint!.dx, startY + dashWidth);
      startY += dashWidth + dashSpace;
    }

    canvas.drawPath(path, verticalLinePaint);

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    canvas.drawRRect(rrect, tooltipPaint);

    textPainter.paint(
      canvas,
      Offset(
        tooltipPosition.dx + 8,
        tooltipPosition.dy + (tooltipHeight / 2) - (textPainter.height / 2),
      ),
    );


    final int touchedIndex = _getTouchedIndexFromTouchPoint(touchPoint!, chartWidth, leftPadding);
    if (touchedIndex >= 0 && touchedIndex < salesData.length) {
      final data = salesData[touchedIndex];
      final x = leftPadding + touchedIndex * (chartWidth / (salesData.length - 1));
      final y = topPadding + (chartHeight - (data.salesValue! / _maxSalesValue(salesData)) * chartHeight);

      final label = DateFormat('MM/dd').format(data.date);
      final labelTextStyle = const TextStyle(color: Colors.black, fontSize: 9); // Smaller font size
      final labelTextSpan = TextSpan(text: label, style: labelTextStyle);
      final labelTextPainter = TextPainter(
        text: labelTextSpan,
        textDirection: ui.TextDirection.ltr,
      );
      labelTextPainter.layout(minWidth: 0, maxWidth: chartWidth);

      canvas.save();
      canvas.translate(x, size.height - bottomPadding + 10);
      canvas.rotate(-45 * 3.1415927 / 180);
      labelTextPainter.paint(canvas, Offset(-labelTextPainter.width / 2, 0));
      canvas.restore();
    }
  }

  int _getTouchedIndexFromTouchPoint(Offset touchPoint, double chartWidth, double leftPadding) {
    final double stepWidth = chartWidth / (salesData.length - 1);
    int touchedIndex = ((touchPoint.dx - leftPadding) / stepWidth).round();
    if (touchedIndex >= 1 && touchedIndex < salesData.length) {
      final double midpointX = leftPadding + (touchedIndex - 1) * stepWidth + stepWidth / 2;
      if (touchPoint.dx < midpointX) {
        touchedIndex -= 1;
      }
    }
    return touchedIndex;
  }

  double _maxSalesValue(List<SalesData> data) {
    return data.map((e) => e.salesValue).reduce((a, b) => a! > b! ? a : b)!;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}