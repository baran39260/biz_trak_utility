import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

List<SalesData> generateSalesData() {
  // ایجاد داده‌های نمونه برای 20 روز با روزهای غیر متوالی
  List<SalesData> salesData = [
    SalesData(date: DateTime(2023, 6, 1), salesValue: 500),
    SalesData(date: DateTime(2023, 6, 3), salesValue: 1500),
    SalesData(date: DateTime(2023, 6, 3), salesValue: 500),
    SalesData(date: DateTime(2023, 6, 5), salesValue: 2000),
    SalesData(date: DateTime(2023, 6, 7), salesValue: 1200),
    SalesData(date: DateTime(2023, 6, 9), salesValue: 800),
    SalesData(date: DateTime(2023, 6, 11), salesValue: 1500),
    SalesData(date: DateTime(2023, 6, 13), salesValue: 1000),
    SalesData(date: DateTime(2023, 6, 13), salesValue: 1200),
    SalesData(date: DateTime(2023, 6, 15), salesValue: 2500),
    SalesData(date: DateTime(2023, 6, 17), salesValue: 3000),
    SalesData(date: DateTime(2023, 6, 19), salesValue: 400),
  ];

  return calculateDailySales(salesData);
}

List<SalesData> calculateDailySales(List<SalesData> salesData) {
  Map<DateTime, double> dailySalesMap = {};

  for (var data in salesData) {
    if (dailySalesMap.containsKey(data.date)) {
      dailySalesMap[data.date] = dailySalesMap[data.date]! + data.salesValue!;
    } else {
      dailySalesMap[data.date] = data.salesValue!;
    }
  }

  return dailySalesMap.entries
      .map((entry) => SalesData(date: entry.key, salesValue: entry.value))
      .toList();
}

class SalesData {
  final DateTime date;
  final double? salesValue;

  SalesData({required this.date, this.salesValue});
}

class SalesChart extends StatefulWidget {
  final List<SalesData> salesData;

  const SalesChart({Key? key, required this.salesData}) : super(key: key);

  @override
  _SalesChartState createState() => _SalesChartState();
}

class _SalesChartState extends State<SalesChart> {
  final GlobalKey _paintKey = GlobalKey();
  Offset? _touchPoint;
  SalesData? _selectedData;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) {
        _updateTouchPoint(details.localPosition);
      },
      onPanUpdate: (details) {
        _updateTouchPoint(details.localPosition);
      },
      onPanEnd: (details) {
        setState(() {
          _touchPoint = null;
          _selectedData = null;
        });
      },
      child: Container(
        width: double.infinity,
        height: 300,
        child: CustomPaint(
          key: _paintKey,
          painter: SalesChartPainter(
            widget.salesData,
            touchPoint: _touchPoint,
            selectedData: _selectedData,
          ),
        ),
      ),
    );
  }

  void _updateTouchPoint(Offset localPosition) {
    setState(() {
      _touchPoint = localPosition;
      _selectedData = _getSalesDataFromTouchPoint(localPosition);
    });
  }

  SalesData? _getSalesDataFromTouchPoint(Offset touchPoint) {
    final double chartWidth = MediaQuery.of(context).size.width - 60;
    final double stepWidth = chartWidth / widget.salesData.length;
    final int touchedIndex = (touchPoint.dx - 30) ~/ stepWidth;
    if (touchedIndex >= 0 && touchedIndex < widget.salesData.length) {
      return widget.salesData[touchedIndex];
    }
    return null;
  }
}

class SalesChartPainter extends CustomPainter {
  final List<SalesData> salesData;
  final Offset? touchPoint;
  final SalesData? selectedData;
  final double padding = 30.0;

  SalesChartPainter(this.salesData, {this.touchPoint, this.selectedData});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xff4259A4)
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    final double chartHeight = size.height - 2 * padding;
    final double chartWidth = size.width - 2 * padding;

    _drawGridLines(canvas, size, chartWidth, chartHeight);
    _drawAxes(canvas, size, chartWidth, chartHeight);
    _drawSalesData(canvas, size, chartWidth, chartHeight);
    _drawDataPoints(canvas, chartWidth, chartHeight);

    if (touchPoint != null && selectedData != null) {
      _drawTooltip(canvas, size, chartWidth, chartHeight);
    }
  }

  void _drawGridLines(Canvas canvas, Size size, double chartWidth, double chartHeight) {
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    const int horizontalLines = 5;

    for (int i = 0; i <= horizontalLines; i++) {
      final y = size.height - padding - (i * chartHeight / horizontalLines);
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }
  }

  void _drawAxes(Canvas canvas, Size size, double chartWidth, double chartHeight) {
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );

    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );

    final textStyle = const TextStyle(color: Colors.black, fontSize: 10);
    final maxValue = salesData.map((data) => data.salesValue).reduce((a, b) => a! > b! ? a : b)! * 1.1; // Increased height
    const minValue = 0;
    final step = (maxValue - minValue) / 5;

    for (int i = 0; i <= 5; i++) {
      final y = size.height - padding - (i * chartHeight / 5);
      final label = (minValue + (step * i)).toStringAsFixed(0);
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: chartWidth);
      textPainter.paint(canvas, Offset(padding - 30, y - 6));
    }

    for (int i = 0; i < salesData.length; i++) {
      // فقط هر چند روز یکبار تاریخ را نمایش دهید
      if (i % (salesData.length ~/ 10 + 1) != 0) continue;

      final data = salesData[i];
      final x = padding + i * (chartWidth / (salesData.length - 1));
      final label = DateFormat('MM/dd').format(data.date);
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: chartWidth);

      canvas.save();
      canvas.translate(x, size.height - padding + 10); // Adjusted the Y position to be closer to the circle
      canvas.rotate(-45 * 3.1415927 / 180); // Rotate text for better fitting
      textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
      canvas.restore();
    }
  }

  void _drawSalesData(Canvas canvas, Size size, double chartWidth, double chartHeight) {
    final path = Path();
    final fillPath = Path();
    bool isFirstPoint = true;
    final double maxValue = salesData.map((data) => data.salesValue).reduce((a, b) => a! > b! ? a : b)! * 1.1; // Increased height

    for (int i = 0; i < salesData.length; i++) {
      final data = salesData[i];
      final x = padding + i * (chartWidth / (salesData.length - 1));
      final y = padding + (chartHeight - (data.salesValue! / maxValue) * chartHeight);

      if (isFirstPoint) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
        isFirstPoint = false;
      } else {
        final previousX = padding + (i - 1) * (chartWidth / (salesData.length - 1));
        final previousY = padding + (chartHeight - (salesData[i - 1].salesValue! / maxValue) * chartHeight);
        final controlPointX1 = (previousX + x) / 2;
        final controlPointX2 = (previousX + x) / 2;
        path.cubicTo(controlPointX1, previousY, controlPointX2, y, x, y);
        fillPath.cubicTo(controlPointX1, previousY, controlPointX2, y, x, y);
      }
    }

    fillPath.lineTo(size.width - padding, size.height - padding);
    fillPath.lineTo(padding, size.height - padding);
    fillPath.close();

    final linePaint = Paint()
      ..color = const Color(0xff4259A4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(padding, padding),
        Offset(padding, size.height - padding),
        [const Color(0xff74ebd5), const Color(0xffACB6E5)], // جذاب تر
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  void _drawDataPoints(Canvas canvas, double chartWidth, double chartHeight) {
    final double maxValue = salesData.map((data) => data.salesValue).reduce((a, b) => a! > b! ? a : b)! * 1.1; // Increased height

    for (int i = 0; i < salesData.length; i++) {
      final data = salesData[i];
      final x = padding + i * (chartWidth / (salesData.length - 1));
      final y = padding + (chartHeight - (data.salesValue! / maxValue) * chartHeight);

      final pointPaint = Paint()
        ..color = const Color(0xff052ba4)
        ..style = PaintingStyle.fill;

      final outlinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(Offset(x, y), 4.0, outlinePaint);
      canvas.drawCircle(Offset(x, y), 4.0, pointPaint);
    }
  }

  void _drawTooltip(Canvas canvas, Size size, double chartWidth, double chartHeight) {
    final tooltipPaint = Paint()
      ..color = Colors.blueGrey[700]!.withOpacity(0.9)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    final textSpan = TextSpan(
      text: '${selectedData?.salesValue?.toStringAsFixed(2) ?? 'No Data'}',
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

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    canvas.drawRRect(rrect, tooltipPaint);

    textPainter.paint(
      canvas,
      Offset(
        tooltipPosition.dx + 8,
        tooltipPosition.dy + (tooltipHeight / 2) - (textPainter.height / 2),
      ),
    );

    final verticalLinePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, 1);

    final path = Path();
    final dashWidth = 5;
    final dashSpace = 5;
    double startY = padding;
    while (startY < size.height - padding) {
      path.moveTo(touchPoint!.dx, startY);
      path.lineTo(touchPoint!.dx, startY + dashWidth);
      startY += dashWidth + dashSpace;
    }

    canvas.drawPath(path, verticalLinePaint);

    final int touchedIndex = _getTouchedIndexFromTouchPoint(touchPoint!, size.width, chartWidth);
    if (touchedIndex >= 0 && touchedIndex < salesData.length) {
      final data = salesData[touchedIndex];
      final x = padding + touchedIndex * (chartWidth / (salesData.length - 1));
      final y = padding + (chartHeight - (data.salesValue! / _maxSalesValue(salesData)) * chartHeight);

      final label = DateFormat('MM/dd').format(data.date);
      final labelTextStyle = const TextStyle(color: Colors.black, fontSize: 10);
      final labelTextSpan = TextSpan(text: label, style: labelTextStyle);
      final labelTextPainter = TextPainter(
        text: labelTextSpan,
        textDirection: ui.TextDirection.ltr,
      );
      labelTextPainter.layout(minWidth: 0, maxWidth: chartWidth);

      canvas.save();
      canvas.translate(x, size.height - padding + 10); // Adjusted the Y position to be closer to the circle
      canvas.rotate(-45 * 3.1415927 / 180); // Rotate text for better fitting
      labelTextPainter.paint(canvas, Offset(-labelTextPainter.width / 2, 0));
      canvas.restore();
    }
  }

  int _getTouchedIndexFromTouchPoint(Offset touchPoint, double screenWidth, double chartWidth) {
    final double stepWidth = chartWidth / (salesData.length - 1);
    int touchedIndex = ((touchPoint.dx - padding) / stepWidth).round();
    touchedIndex = touchedIndex.clamp(0, salesData.length - 1);
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
