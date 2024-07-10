import 'dart:math';
import 'package:biz_trak_utility/utility.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class CostIncomePage extends StatefulWidget {
  final ChartConfigStruct config;
  final CurrencyDataStruct currencyData;
  final double width;
  final double height;

  const CostIncomePage({
    Key? key,
    required this.config,
    required this.currencyData,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  _CostIncomePageState createState() => _CostIncomePageState();
}

class _CostIncomePageState extends State<CostIncomePage> {
  late CurrencyDataStruct modifiedCurrencyData;

  @override
  void initState() {
    super.initState();
    modifiedCurrencyData = widget.config.showCurrency == false
        ? CurrencyDataStruct(
      symbol: widget.currencyData.symbol,
      showSymbol: false,
      symbolOnLeft: widget.currencyData.symbolOnLeft,
      spaceBetweenAmountAndSymbol: widget.currencyData.spaceBetweenAmountAndSymbol,
      thousandsSeparator: widget.currencyData.thousandsSeparator,
      decimalSeparator: widget.currencyData.decimalSeparator,
      digit: widget.currencyData.digit,
      useParenthesesForNegatives: widget.currencyData.useParenthesesForNegatives,
    )
        : widget.currencyData;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Chart display area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: CostIncomeChart(
                data: generateCostIncomeData(),
                currencyData: modifiedCurrencyData,
                config: widget.config,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CostIncomeChart extends StatefulWidget {
  final List<CostIncomeData> data;
  final CurrencyDataStruct currencyData;
  final ChartConfigStruct config;

  const CostIncomeChart({
    Key? key,
    required this.data,
    required this.currencyData,
    required this.config,
  }) : super(key: key);

  @override
  _CostIncomeChartState createState() => _CostIncomeChartState();
}

class _CostIncomeChartState extends State<CostIncomeChart> with SingleTickerProviderStateMixin {
  Offset? _tapPosition;
  CostIncomeData? _selectedData;
  bool _isShortFormat = false;

  // Handle tap events to display tooltips with detailed information
  void _handleTapDown(TapDownDetails details, CostIncomeData data, bool isShortFormat) {
    setState(() {
      _tapPosition = details.globalPosition;
      _selectedData = data;
      _isShortFormat = isShortFormat;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);
            final chartWidth = constraints.maxWidth - 16; // Adjust based on padding
            final columnWidth = chartWidth / (widget.data.length * 2);
            final index = ((localPosition.dx - 8) / (columnWidth * 2)).floor();
            if (index >= 0 && index < widget.data.length) {
              final data = widget.data[index];
              final isShortFormat = _checkTooltipWidth(data);
              _handleTapDown(details, data, isShortFormat);
            }
          },
          child: Stack(
            children: [
              // Main chart area
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: CustomPaint(
                  painter: CostIncomeChartPainter(
                    widget.data,
                    widget.currencyData,
                    widget.config,
                  ),
                ),
              ),
              // Tooltip display
              if (_tapPosition != null && _selectedData != null)
                Positioned(
                  left: _tapPosition!.dx,
                  top: _tapPosition!.dy,
                  child: Tooltip(
                    message: _isShortFormat
                        ? formatCurrency(_selectedData!.incomeValue, widget.currencyData)
                        : formatCurrency(_selectedData!.incomeValue, widget.currencyData),
                    child: Container(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Check if the tooltip width exceeds the available width
  bool _checkTooltipWidth(CostIncomeData data) {
    final sampleValue = formatCurrency(data.incomeValue, widget.currencyData);
    final textPainter = TextPainter(
      text: TextSpan(text: sampleValue, style: TextStyle(fontSize: 10)),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width > 50; // Adjust based on available width
  }
}

class CostIncomeChartPainter extends CustomPainter {
  final List<CostIncomeData> data;
  final CurrencyDataStruct currencyData;
  final ChartConfigStruct config;

  final double paddingTopBottom = 16.0;
  final double paddingRight = 8.0;
  final double paddingLeft;
  final double borderRadius = 8.0;
  final double textPadding = 5.0; // Reduced text padding for better spacing
  final double extraHeightFactor = 1.1; // Factor to increase the chart height
  final TextStyle textStyle = TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold);
  final DateFormat dateFormat = DateFormat('E');

  CostIncomeChartPainter(this.data, this.currencyData, this.config)
      : paddingLeft = config.showYAxis == true ? 50.0 : 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final double chartHeight = size.height - 2 * paddingTopBottom;
    final double chartWidth = size.width - (paddingLeft + paddingRight);
    final double maxValue = _roundToNearest(_maxValue(data) * extraHeightFactor);

    bool useShortFormatYAxis = _checkLabelWidth(size, maxValue);
    bool useShortFormatTooltip = _checkTooltipWidth(size);

    if (config.showGridLines == true) {
      _drawGridLines(canvas, size, chartWidth, chartHeight, maxValue, useShortFormatYAxis);
    }

    _drawAxes(canvas, size, chartWidth, chartHeight, maxValue, useShortFormatYAxis);

    if (config.chartType == ChartType.Bar) {
      _drawBarChartData(canvas, size, chartWidth, chartHeight, maxValue, useShortFormatTooltip);
    } else {
      _drawLineChartData(canvas, size, chartWidth, chartHeight, maxValue, useShortFormatTooltip);
    }
  }

  // Check if Y axis labels need short format (e.g., 1K, 2M)
  bool _checkLabelWidth(Size size, double maxValue) {
    final step = maxValue / 5;
    for (int i = 0; i <= 5; i++) {
      String label = formatCurrency(step * i, currencyData);
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      if (textPainter.width > paddingLeft - 10) {
        return true;
      }
    }
    return false;
  }

  // Check if tooltip width exceeds available width
  bool _checkTooltipWidth(Size size) {
    final sampleValue = formatCurrency(1000, currencyData);
    final textPainter = TextPainter(
      text: TextSpan(text: sampleValue, style: textStyle),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width > size.width / data.length;
  }

  // Draw the axes
  void _drawAxes(Canvas canvas, Size size, double chartWidth, double chartHeight, double maxValue, bool useShortFormatYAxis) {
    final axisPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.0;

    // Draw horizontal axis (always draw this)
    canvas.drawLine(
      Offset(paddingLeft, size.height - paddingTopBottom),
      Offset(size.width - paddingRight, size.height - paddingTopBottom),
      axisPaint,
    );

    if (config.showYAxis == true) {
      // Draw vertical axis if showYAxis is true
      canvas.drawLine(
        Offset(paddingLeft, paddingTopBottom),
        Offset(paddingLeft, size.height - paddingTopBottom),
        axisPaint,
      );
    }

    final step = maxValue / 5;

    if (config.showYAxis == true) {
      for (int i = 0; i <= 5; i++) {
        final y = size.height - paddingTopBottom - (i * chartHeight / 5);
        final label = useShortFormatYAxis ? _formatToK(step * i) : formatCurrency(step * i, currencyData);
        _drawText(canvas, label, Offset(paddingLeft - 45, y - 10)); // Adjusted position
      }
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
      final x = paddingLeft + (i + (config.chartType == ChartType.Bar ? 0.4 : 0.5)) * (chartWidth / data.length);

      _drawText(canvas, label, Offset(x, size.height - paddingTopBottom + 15), center: true); // Adjusted position
    }
  }

  // Draw the grid lines
  void _drawGridLines(Canvas canvas, Size size, double chartWidth, double chartHeight, double maxValue, bool useShortFormatYAxis) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1.0;

    final horizontalLines = 5;
    final step = maxValue / 5;

    for (int i = 0; i <= horizontalLines; i++) {
      final y = size.height - paddingTopBottom - (i * chartHeight / horizontalLines);
      final label = useShortFormatYAxis ? _formatToK(step * i) : formatCurrency(step * i, currencyData);
      if (config.showYAxis == true) {
        _drawText(canvas, label, Offset(paddingLeft - 45, y - 10)); // Adjusted position
      }
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );
    }
  }

  // Adjust brightness of a color
  Color _adjustColorBrightness(Color color, double factor) {
    return Color.fromARGB(
      color.alpha,
      (color.red * factor).clamp(0, 255).toInt(),
      (color.green * factor).clamp(0, 255).toInt(),
      (color.blue * factor).clamp(0, 255).toInt(),
    );
  }

  // Draw bar chart data
  void _drawBarChartData(Canvas canvas, Size size, double chartWidth, double chartHeight, double maxValue, bool useShortFormatTooltip) {
    final double totalColumnWidth = chartWidth / data.length;
    final double columnWidth = totalColumnWidth * 0.3; // Adjust the width to create space between columns

    for (int i = 0; i < data.length; i++) {
      final incomeData = data[i].incomeValue;
      final costData = data[i].costValue;

      final incomeColumnHeight = (incomeData / maxValue) * chartHeight;
      final costColumnHeight = (costData / maxValue) * chartHeight;

      final incomeX = paddingLeft + (i * totalColumnWidth) + (totalColumnWidth * 0.1); // Adjusted X position for spacing
      final incomeY = size.height - paddingTopBottom - incomeColumnHeight;

      final costX = incomeX + columnWidth;
      final costY = size.height - paddingTopBottom - costColumnHeight;

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
        ..shader = LinearGradient(
          colors: [
            _adjustColorBrightness(config.purchaseLineColor ?? Colors.green, 0.7),
            _adjustColorBrightness(config.purchaseLineColor ?? Colors.green, 1.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(incomeRect.outerRect);

      final costPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            _adjustColorBrightness(config.salesLineColor ?? Colors.red, 0.7),
            _adjustColorBrightness(config.salesLineColor ?? Colors.red, 1.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(costRect.outerRect);

      canvas.drawRRect(incomeRect, incomePaint);
      canvas.drawRRect(costRect, costPaint);

      if (config.showValues == true) {
        final incomeText = _formatCurrencyWithCheck(incomeData, currencyData, columnWidth);
        final costText = _formatCurrencyWithCheck(costData, currencyData, columnWidth);

        _drawText(canvas, incomeText, Offset(incomeX + columnWidth / 2, incomeY - textPadding), center: true);
        _drawText(canvas, costText, Offset(costX + columnWidth / 2, costY - textPadding), center: true);
      }
    }
  }

  // Draw line chart data
  void _drawLineChartData(Canvas canvas, Size size, double chartWidth, double chartHeight, double maxValue, bool useShortFormatTooltip) {
    final incomeLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _adjustColorBrightness(config.purchaseLineColor ?? Colors.green, 0.7),
          _adjustColorBrightness(config.purchaseLineColor ?? Colors.green, 1.3),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final costLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _adjustColorBrightness(config.salesLineColor ?? Colors.red, 0.7),
          _adjustColorBrightness(config.salesLineColor ?? Colors.red, 1.3),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final incomePath = Path();
    final costPath = Path();

    for (int i = 0; i < data.length; i++) {
      final incomeData = data[i].incomeValue;
      final costData = data[i].costValue;

      final incomeX = paddingLeft + (i + 0.5) * (chartWidth / data.length);
      final incomeY = size.height - paddingTopBottom - (incomeData / maxValue) * chartHeight;

      final costX = incomeX;
      final costY = size.height - paddingTopBottom - (costData / maxValue) * chartHeight;

      if (i == 0) {
        incomePath.moveTo(incomeX, incomeY);
        costPath.moveTo(costX, costY);
      } else {
        incomePath.lineTo(incomeX, incomeY);
        costPath.lineTo(costX, costY);
      }

      if (config.fillBelowLine == true) {
        final incomeGradientPath = Path.from(incomePath);
        incomeGradientPath.lineTo(incomeX, size.height - paddingTopBottom);
        incomeGradientPath.lineTo(paddingLeft, size.height - paddingTopBottom);
        incomeGradientPath.close();

        final costGradientPath = Path.from(costPath);
        costGradientPath.lineTo(costX, size.height - paddingTopBottom);
        costGradientPath.lineTo(paddingLeft, size.height - paddingTopBottom);
        costGradientPath.close();

        final incomeGradient = LinearGradient(
          colors: [config.purchaseLineColor!.withOpacity(0.5), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(paddingLeft, paddingTopBottom, chartWidth, chartHeight));

        final costGradient = LinearGradient(
          colors: [config.salesLineColor!.withOpacity(0.5), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(paddingLeft, paddingTopBottom, chartWidth, chartHeight));

        canvas.drawPath(incomeGradientPath, Paint()..shader = incomeGradient);
        canvas.drawPath(costGradientPath, Paint()..shader = costGradient);
      }
    }

    canvas.drawPath(incomePath, incomeLinePaint);
    canvas.drawPath(costPath, costLinePaint);

    for (int i = 0; i < data.length; i++) {
      final incomeData = data[i].incomeValue;
      final costData = data[i].costValue;

      final incomeX = paddingLeft + (i + 0.5) * (chartWidth / data.length);
      final incomeY = size.height - paddingTopBottom - (incomeData / maxValue) * chartHeight;

      final costX = incomeX;
      final costY = size.height - paddingTopBottom - (costData / maxValue) * chartHeight;

      canvas.drawCircle(Offset(incomeX, incomeY), 4.0, Paint()..color = config.purchaseLineColor!);
      canvas.drawCircle(Offset(costX, costY), 4.0, Paint()..color = config.salesLineColor!);

      final incomeText = _formatCurrencyWithCheck(incomeData, currencyData, chartWidth / data.length);
      final costText = _formatCurrencyWithCheck(costData, currencyData, chartWidth / data.length);

      bool isTextOverlap = (incomeY - costY).abs() < textPadding * 4; // Check if text overlaps

      if (config.showYAxis == true) {
        if (isTextOverlap) {
          // Adjust text positions if they overlap
          _drawText(canvas, incomeText, Offset(incomeX, incomeY - textPadding - 20), center: true);
          _drawText(canvas, costText, Offset(costX, costY + textPadding + 10), center: true);
        } else {
          _drawText(canvas, incomeText, Offset(incomeX, incomeY - textPadding - 10), center: true);
          _drawText(canvas, costText, Offset(costX, costY - textPadding - 10), center: true);
        }
      }
    }
  }

  // Draw text on the canvas
  void _drawText(Canvas canvas, String text, Offset position, {bool center = false}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    final offsetX = center ? position.dx - textPainter.width / 2 : position.dx;
    final offsetY = center ? position.dy - textPainter.height / 2 : position.dy;
    textPainter.paint(canvas, Offset(offsetX, offsetY));
  }

  // Format currency and check if it fits within the available width
  String _formatCurrencyWithCheck(double value, CurrencyDataStruct currencyData, double availableWidth) {
    String formatted = formatCurrency(value, currencyData);
    final textPainter = TextPainter(
      text: TextSpan(text: formatted, style: textStyle),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();

    if (textPainter.width > availableWidth) {
      formatted = _formatToK(value);
    }

    return formatted;
  }

  // Format numbers to K, M, B, etc.
  String _formatToK(double value) {
    final suffixes = ['', 'K', 'M', 'B', 'T'];
    int index = 0;

    while (value >= 1000 && index < suffixes.length - 1) {
      value /= 1000;
      index++;
    }

    return '${value.toStringAsFixed(value < 10 && index > 0 ? 1 : 0)}${suffixes[index]}';
  }

  // Round numbers to the nearest significant figure
  double _roundToNearest(double value) {
    if (value == 0) return 0;

    final log10 = (log(value) / log(10)).floor();
    final divisor = pow(10, log10);
    final roundedValue = (value / divisor).round() * divisor;

    return roundedValue.toDouble();
  }

  // Get the maximum value from the data
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
    return true;
  }
}
