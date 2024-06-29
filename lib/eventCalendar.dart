import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';


class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  String _selectedEvent = "";
  late PageController _pageController;

  final Map<int, Map<int, Map<int, String>>> events = {
    2024: {
      6: {
        3: 'Purchase Order',
        5: 'Sale Order',
        7: 'Client Meeting',
        11: 'Supplier Visit',
        18: 'Inventory Check',
      },
    },
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _focusedDate.year * 12 + _focusedDate.month,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          _buildHeader(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  int year = index ~/ 12;
                  int month = index % 12 + 1;
                  _focusedDate = DateTime(year, month);
                });
              },
              itemBuilder: (context, index) {
                int year = index ~/ 12;
                int month = index % 12 + 1;
                return CustomPaint(
                  size: Size(double.infinity, 400),
                  painter: CalendarPainter(
                    month: month,
                    year: year,
                    events: events,
                    onDayTap: (date) {
                      setState(() {
                        _selectedDate = date;
                        _selectedEvent = events[date.year]?[date.month]?[date.day] ?? "No events";
                      });
                    },
                  ),
                );
              },
            ),
          ),
          if (_selectedEvent.isNotEmpty)
            EventDetails(
              date: _selectedDate,
              event: _selectedEvent,
            ),
        ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
          },
        ),
        Text(
          DateFormat.yMMMM().format(_focusedDate),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: () {
            _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
          },
        ),
      ],
    );
  }
}

class CalendarPainter extends CustomPainter {
  final int month;
  final int year;
  final Map<int, Map<int, Map<int, String>>> events;
  final Function(DateTime) onDayTap;

  CalendarPainter({required this.month, required this.year, required this.events, required this.onDayTap});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );

    // Drawing days of the week
    final daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    for (int i = 0; i < daysOfWeek.length; i++) {
      textPainter.text = TextSpan(
        text: daysOfWeek[i],
        style: TextStyle(fontSize: 16, color: Colors.black),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(i * size.width / 7 + 10, 20));
    }

    // Drawing the days with colored dots
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startDay = DateTime(year, month, 1).weekday % 7;

    final eventDays = events[year]?[month] ?? {};

    for (int i = 0; i < daysInMonth; i++) {
      int row = (i + startDay) ~/ 7;
      int col = (i + startDay) % 7;

      // Draw day number
      textPainter.text = TextSpan(
        text: (i + 1).toString(),
        style: TextStyle(fontSize: 14, color: Colors.black),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(col * size.width / 7 + 10, row * 40 + 60));

      // Draw event dot if there is one
      if (eventDays.containsKey(i + 1)) {
        paint.color = Colors.red;
        canvas.drawCircle(Offset(col * size.width / 7 + 25, row * 40 + 80), 5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class EventDetails extends StatelessWidget {
  final DateTime date;
  final String event;

  const EventDetails({required this.date, required this.event, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event on ${DateFormat.yMMMd().format(date)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            event,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
