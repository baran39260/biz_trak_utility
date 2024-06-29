import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

class CostIncomePage extends StatefulWidget {
  const CostIncomePage({super.key});

  @override
  _CostIncomePageState createState() => _CostIncomePageState();
}

class _CostIncomePageState extends State<CostIncomePage> {
  bool _isBarChart = true;
  bool _fillBelowLine = false;
  bool _showYAxis = true;

  void _toggleChartType(bool value) {
    setState(() {
      _isBarChart = value;
    });
  }

  void _toggleFillBelowLine(bool value) {
    setState(() {
      _fillBelowLine = value;
    });
  }

  void _toggleShowYAxis(bool value) {
    setState(() {
      _showYAxis = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: CostIncomeChart(
                key: ValueKey<bool>(_isBarChart),
                data: generateCostIncomeData(),
                isBarChart: _isBarChart,
                fillBelowLine: _fillBelowLine,
                showYAxis: _showYAxis,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Bar Chart'),
              Switch(
                value: _isBarChart,
                onChanged: _toggleChartType,
              ),
              const Text('Line Chart'),
              const SizedBox(width: 20), // Spacer for better alignment
              const Text('Fill Below Line'),
              Switch(
                value: _fillBelowLine,
                onChanged: _toggleFillBelowLine,
              ),
              const Text('Show Y Axis'),
              Switch(
                value: _showYAxis,
                onChanged: _toggleShowYAxis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<CostIncomeData> generateCostIncomeData() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: index));
      return CostIncomeData(
        date: date,
        incomeValue: Random().nextDouble() * 1000,
        costValue: Random().nextDouble() * 800,
      );
    }).reversed.toList();
  }
}

class CostIncomeData {
  final DateTime date;
  final double incomeValue;
  final double costValue;

  CostIncomeData({
    required this.date,
    required this.incomeValue,
    required this.costValue,
  });
}

class CostIncomeChart extends StatefulWidget {
  final List<CostIncomeData> data;
  final bool isBarChart;
  final bool fillBelowLine;
  final bool showYAxis;

  const CostIncomeChart({
    Key? key,
    required this.data,
    required this.isBarChart,
    required this.fillBelowLine,
    required this.showYAxis,
  }) : super(key: key);

  @override
  _CostIncomeChartState createState() => _CostIncomeChartState();
}

class _CostIncomeChartState extends State<CostIncomeChart> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: CustomPaint(
            painter: CostIncomeChartPainter(
              widget.data,
              widget.isBarChart,
              widget.fillBelowLine,
              widget.showYAxis,
            ),
          ),
        );
      },
    );
  }
}

class CostIncomeChartPainter extends CustomPainter {
  final List<CostIncomeData> data;
  final bool isBarChart;
  final bool fillBelowLine;
  final bool showYAxis;
  final double padding = 30.0;
  final double borderRadius = 8.0;
  final double textPadding = 10.0;
  final double extraHeightFactor = 1.1; // Factor to increase the chart height
  final TextStyle textStyle = TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold);
  final DateFormat dateFormat = DateFormat('E');

  CostIncomeChartPainter(this.data, this.isBarChart, this.fillBelowLine, this.showYAxis);

  @override
  void paint(Canvas canvas, Size size) {
    final double chartHeight = size.height - 2 * padding;
    final double chartWidth = size.width - 2 * padding;
    final double maxValue = _maxValue(data) * extraHeightFactor;

    _drawGridLines(canvas, size, chartWidth, chartHeight, maxValue);

    if (showYAxis) {
      _drawAxes(canvas, size, chartWidth, chartHeight, maxValue);
    }

    if (isBarChart) {
      _drawBarChartData(canvas, size, chartWidth, chartHeight, maxValue);
    } else {
      _drawLineChartData(canvas, size, chartWidth, chartHeight, maxValue);
    }
  }

  void _drawAxes(Canvas canvas, Size size, double chartWidth, double chartHeight, double maxValue) {
    final axisPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.0;

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

    final step = maxValue / 5;

    for (int i = 0; i <= 5; i++) {
      final y = size.height - padding - (i * chartHeight / 5);
      final label = (step * i).toStringAsFixed(0);
      _drawText(canvas, label, Offset(padding - 40, y - 10));
    }

    final weekdays = <int, String>{
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };

    for (int i = 0; i < data.length; i++) {
      final dayOfWeek = data[i].date.weekday;
      final label = weekdays[dayOfWeek] ?? '';
      final x = padding + (i + 0.5) * (chartWidth / data.length);

      _drawText(canvas, label, Offset(x - 20, size.height - padding + 10));
    }
  }

  void _drawBarChartData(Canvas canvas, Size size, double chartWidth, double chartHeight, double maxValue) {
    final double totalColumnWidth = chartWidth / (data.length * 2);
    final double columnWidth = totalColumnWidth * 0.7;

    for (int i = 0; i < data.length; i++) {
      final incomeData = data[i].incomeValue;
      final costData = data[i].costValue;

      final incomeColumnHeight = (incomeData / maxValue) * chartHeight;
      final costColumnHeight = (costData / maxValue) * chartHeight;

      final incomeX = padding + i * totalColumnWidth * 2;
      final incomeY = size.height - padding - incomeColumnHeight;

      final costX = incomeX + columnWidth;
      final costY = size.height - padding - costColumnHeight;

      final incomeRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(incomeX, incomeY, columnWidth, incomeColumnHeight),
        topLeft: Radius.circular(borderRadius),
        topRight: Radius.circular(borderRadius),
      );

      final costRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(costX, costY, columnWidth, costColumnHeight),
        topLeft: Radius.circular(borderRadius),
        topRight: Radius.circular(borderRadius),
      );

      final incomePaint = Paint()
        ..color = Colors.green
        ..shader = LinearGradient(
          colors: [Colors.green[700]!, Colors.green[300]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(incomeRect.outerRect);

      final costPaint = Paint()
        ..color = Colors.red
        ..shader = LinearGradient(
          colors: [Colors.red[700]!, Colors.red[300]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(costRect.outerRect);

      canvas.drawRRect(incomeRect, incomePaint);
      canvas.drawRRect(costRect, costPaint);

      final incomeText = NumberFormat.simpleCurrency(locale: 'en_US').format(incomeData);
      final costText = NumberFormat.simpleCurrency(locale: 'en_US').format(costData);

      _drawText(canvas, incomeText, Offset(incomeX + columnWidth / 2, incomeY - textPadding), center: true);
      _drawText(canvas, costText, Offset(costX + columnWidth / 2, costY - textPadding), center: true);
    }
  }

  void _drawLineChartData(Canvas canvas, Size size, double chartWidth, double chartHeight, double maxValue) {
    final incomeLinePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final costLinePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final incomePath = Path();
    final costPath = Path();

    for (int i = 0; i < data.length; i++) {
      final incomeData = data[i].incomeValue;
      final costData = data[i].costValue;

      final incomeX = padding + (i + 0.5) * (chartWidth / data.length);
      final incomeY = size.height - padding - (incomeData / maxValue) * chartHeight;

      final costX = incomeX;
      final costY = size.height - padding - (costData / maxValue) * chartHeight;

      if (i == 0) {
        incomePath.moveTo(incomeX, incomeY);
        costPath.moveTo(costX, costY);
      } else {
        incomePath.lineTo(incomeX, incomeY);
        costPath.lineTo(costX, costY);
      }

      if (fillBelowLine) {
        final incomeGradientPath = Path.from(incomePath);
        incomeGradientPath.lineTo(incomeX, size.height - padding);
        incomeGradientPath.lineTo(padding, size.height - padding);
        incomeGradientPath.close();

        final costGradientPath = Path.from(costPath);
        costGradientPath.lineTo(costX, size.height - padding);
        costGradientPath.lineTo(padding, size.height - padding);
        costGradientPath.close();

        final incomeGradient = LinearGradient(
          colors: [Colors.green.withOpacity(0.5), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(padding, padding, chartWidth, chartHeight));

        final costGradient = LinearGradient(
          colors: [Colors.red.withOpacity(0.5), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(padding, padding, chartWidth, chartHeight));

        canvas.drawPath(incomeGradientPath, Paint()..shader = incomeGradient);
        canvas.drawPath(costGradientPath, Paint()..shader = costGradient);
      }
    }

    canvas.drawPath(incomePath, incomeLinePaint);
    canvas.drawPath(costPath, costLinePaint);

    for (int i = 0; i < data.length; i++) {
      final incomeData = data[i].incomeValue;
      final costData = data[i].costValue;

      final incomeX = padding + (i + 0.5) * (chartWidth / data.length);
      final incomeY = size.height - padding - (incomeData / maxValue) * chartHeight;

      final costX = incomeX;
      final costY = size.height - padding - (costData / maxValue) * chartHeight;

      canvas.drawCircle(Offset(incomeX, incomeY), 4.0, Paint()..color = Colors.green);
      canvas.drawCircle(Offset(costX, costY), 4.0, Paint()..color = Colors.red);

      final incomeText = NumberFormat.simpleCurrency(locale: 'en_US').format(incomeData);
      final costText = NumberFormat.simpleCurrency(locale: 'en_US').format(costData);

      _drawText(canvas, incomeText, Offset(incomeX, incomeY - textPadding - 10), center: true);
      _drawText(canvas, costText, Offset(costX, costY - textPadding - 10), center: true);
    }
  }

  void _drawGridLines(Canvas canvas, Size size, double chartWidth, double chartHeight, double maxValue) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1.0;

    final horizontalLines = 5;
    final step = maxValue / 5;

    for (int i = 0; i <= horizontalLines; i++) {
      final y = size.height - padding - (i * chartHeight / horizontalLines);
      final label = (step * i).toStringAsFixed(0);
      _drawText(canvas, label, Offset(padding - 40, y - 10));
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, {bool center = false}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final offsetX = center ? position.dx - textPainter.width / 2 : position.dx;
    final offsetY = center ? position.dy - textPainter.height / 2 : position.dy;
    textPainter.paint(canvas, Offset(offsetX, offsetY));
  }

  double _maxValue(List<CostIncomeData> data) {
    double max = 0;
    for (final item in data) {
      if (item.incomeValue > max) max = item.incomeValue;
      if (item.costValue > max) max = item.costValue;
    }
    return max;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
