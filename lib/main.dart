import 'package:flutter/material.dart';
import 'pieChart.dart';
import 'dailyIncomeExpense.dart';
import 'lineChart.dart';
import 'eventCalendar.dart';
import 'tab5.dart';
import 'tab6.dart';
import 'tab7.dart';
import 'tab8.dart';
import 'tab9.dart';
import 'tab10.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<SalesData> salesData = generateSalesData();

    return Scaffold(
      appBar: AppBar(
        title: Text('10 Tab Example'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Pie Chart'),
            Tab(text: 'Daily Income Expense'),
            Tab(text: 'Sales Chart'),
            Tab(text: 'Custom Calendar'),
            Tab(text: 'Tab 5'),
            Tab(text: 'Tab 6'),
            Tab(text: 'Tab 7'),
            Tab(text: 'Tab 8'),
            Tab(text: 'Tab 9'),
            Tab(text: 'Tab 10'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PieChartScreen(),
          CostIncomePage(),
          SalesChart(salesData: salesData),
          CalendarScreen(),
          Tab5(),
          Tab6(),
          Tab7(),
          Tab8(),
          Tab9(),
          Tab10(),
        ],
      ),
    );
  }
}
