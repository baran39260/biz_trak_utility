import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime currentDate = DateTime.now();
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 500, // تنظیم حداکثر عرض
                maxHeight: 600, // تنظیم حداکثر ارتفاع
              ),
              child: AspectRatio(
                aspectRatio: 1, // حفظ نسبت ابعاد 1:1
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back),
                              onPressed: () {
                                setState(() {
                                  currentDate = DateTime(currentDate.year, currentDate.month - 1);
                                  selectedDate = null;
                                });
                              },
                            ),
                            Text(
                              '${DateFormat.MMMM().format(currentDate)} ${currentDate.year}',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(Icons.arrow_forward),
                              onPressed: () {
                                setState(() {
                                  currentDate = DateTime(currentDate.year, currentDate.month + 1);
                                  selectedDate = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      _buildDaysOfWeekRow(),
                      Expanded(
                        child: GestureDetector(
                          onTapDown: (details) {
                            _handleTap(details.localPosition, constraints.biggest);
                          },
                          child: CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxWidth),
                            painter: CalendarPainter(currentDate, selectedDate),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDaysOfWeekRow() {
    List<String> daysOfWeek = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: daysOfWeek
          .map((day) => Container(
        width: 500 / 7,
        child: Text(
          day,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black),
        ),
      ))
          .toList(),
    );
  }

  void _handleTap(Offset position, Size size) {
    double daySize = size.width / 7;
    int day = (position.dx / daySize).floor();
    int week = (position.dy / daySize).floor();

    DateTime firstDayOfMonth = DateTime(currentDate.year, currentDate.month, 1);
    int startDay = firstDayOfMonth.weekday - 1;
    int dayNumber = week * 7 + day - startDay + 1;

    if (dayNumber > 0 && dayNumber <= daysInMonth(currentDate.year, currentDate.month)) {
      setState(() {
        selectedDate = DateTime(currentDate.year, currentDate.month, dayNumber);
      });
    }
  }

  int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}

class CalendarPainter extends CustomPainter {
  final DateTime currentDate;
  final DateTime? selectedDate;

  CalendarPainter(this.currentDate, this.selectedDate);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..style = PaintingStyle.fill;

    var textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );

    double daySize = size.width / 7;
    double radius = daySize / 2.5;

    DateTime firstDayOfMonth = DateTime(currentDate.year, currentDate.month, 1);
    int startDay = firstDayOfMonth.weekday - 1;

    // Display days of the previous month
    _drawPreviousMonthDays(canvas, textPainter, startDay, daySize);

    // Display days of the current month
    _drawCurrentMonthDays(canvas, textPainter, startDay, daySize, radius);

    // Display days of the next month
    _drawNextMonthDays(canvas, textPainter, startDay, daySize);
  }

  void _drawPreviousMonthDays(Canvas canvas, TextPainter textPainter, int startDay, double daySize) {
    DateTime previousMonth = DateTime(currentDate.year, currentDate.month - 1);
    int daysInPreviousMonth = daysInMonth(previousMonth.year, previousMonth.month);
    for (int i = startDay - 1; i >= 0; i--) {
      int dayNumber = daysInPreviousMonth - (startDay - 1 - i);
      double x = i * daySize + daySize / 2;
      double y = daySize / 2;

      textPainter.text = TextSpan(
        text: '$dayNumber',
        style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
  }

  void _drawCurrentMonthDays(Canvas canvas, TextPainter textPainter, int startDay, double daySize, double radius) {
    var paint = Paint()..style = PaintingStyle.fill;
    for (int week = 0; week < 6; week++) {
      for (int day = 0; day < 7; day++) {
        int dayNumber = week * 7 + day - startDay + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth(currentDate.year, currentDate.month)) {
          continue;
        }

        double x = day * daySize + daySize / 2;
        double y = week * daySize + daySize / 2;

        bool isSelected = selectedDate != null &&
            selectedDate!.year == currentDate.year &&
            selectedDate!.month == currentDate.month &&
            selectedDate!.day == dayNumber;

        bool isToday = DateTime.now().year == currentDate.year &&
            DateTime.now().month == currentDate.month &&
            DateTime.now().day == dayNumber;

        if (isToday || isSelected) {
          paint.color = isToday ? Colors.deepOrange : Colors.orange.withOpacity(0.5);

          Rect rect = Rect.fromCenter(center: Offset(x, y), width: daySize * 0.8, height: daySize * 0.8);
          RRect rRect = RRect.fromRectAndRadius(rect, Radius.circular(10));

          canvas.drawRRect(rRect, paint);
        }

        textPainter.text = TextSpan(
          text: '$dayNumber',
          style: TextStyle(color: isToday || isSelected ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
      }
    }
  }

  void _drawNextMonthDays(Canvas canvas, TextPainter textPainter, int startDay, double daySize) {
    int endDay = daysInMonth(currentDate.year, currentDate.month) + startDay;
    int lastRowDays = (endDay % 7 == 0) ? 0 : 7 - (endDay % 7); // Number of days to display in the last row
    for (int i = endDay; i < endDay + lastRowDays; i++) {
      int dayNumber = i - endDay + 1;
      double x = (i % 7) * daySize + daySize / 2;
      double y = (i ~/ 7) * daySize + daySize / 2;

      textPainter.text = TextSpan(
        text: '$dayNumber',
        style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
  }

  int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
