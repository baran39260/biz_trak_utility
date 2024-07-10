
import 'package:flutter/material.dart';
import 'generate_pdf.dart';

import 'utility.dart';
import 'pieChart.dart';
import 'dailyIncomeExpense.dart';
import 'lineChart.dart';
import 'eventCalendar.dart';
import 'DonutChart.dart';
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
    List<InvoicesRecord> sampleInvoices = generateSampleInvoices();

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
            Tab(text: 'Generate PDF'),
            Tab(text: 'Donut Chart'),
            Tab(text: 'Bitcoin Price'),
            Tab(text: 'Tab 8'),
            Tab(text: 'Tab 9'),
            Tab(text: 'Tab 10'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PieChartScreen(
          ),
          CostIncomePage(height: 400,width: double.infinity,currencyData: CurrencyDataStruct(symbol: '\$', showSymbol: true, symbolOnLeft: true, spaceBetweenAmountAndSymbol: true, thousandsSeparator: ',', decimalSeparator: '.', digit: 2, useParenthesesForNegatives: true),
            config: ChartConfigStruct(
              chartType: ChartType.Line,
              fillBelowLine: true,
              purchaseLineColor: Colors.amber,
              salesLineColor: Colors.red,
              showCurrency: false,
              showGridLines: true,
              showLabels: false,
              showValues: true,
              showYAxis: true,

            ),),
          SalesChart(
            currencyData: CurrencyDataStruct(symbol: '\$', showSymbol: true, symbolOnLeft: true, spaceBetweenAmountAndSymbol: true, thousandsSeparator: ',', decimalSeparator: '.', digit: 2, useParenthesesForNegatives: true),
            height: 450,
            width: double.infinity,
            salesData: salesData,
            config: ChartConfigStruct(
              fillBelowLine: true,
              salesLineColor: Colors.amber,
              showCurrency: true,
              showGridLines: true,
              showLabels: true,
              showValues: true,
              showYAxis: true,

            ),
          ),
          CalendarScreen(
            // invoices: [
            //   InvoicesRecord(
            //     invoiceType: 0,
            //     generalInvoiceInfo: GeneralInvoiceInfo(
            //       creationDate: DateTime.now().add(Duration(days: 1)),
            //       dueDate: DateTime.now().add(Duration(days: 5)),
            //       invoiceNumber: 'INV001',
            //     ),
            //   ),
            //   InvoicesRecord(
            //     invoiceType: 1,
            //     generalInvoiceInfo: GeneralInvoiceInfo(
            //       creationDate: DateTime.now().add(Duration(days: 2)),
            //       dueDate: DateTime.now().add(Duration(days: 10)),
            //       invoiceNumber: 'INV002',
            //     ),
            //   ),
            //   InvoicesRecord(
            //     invoiceType: 0,
            //     generalInvoiceInfo: GeneralInvoiceInfo(
            //       creationDate: DateTime.now().add(Duration(days: 6)),
            //       dueDate: DateTime.now().add(Duration(days: 13)),
            //       invoiceNumber: 'INV003',
            //     ),
            //   ),
            //   InvoicesRecord(
            //     invoiceType: 1,
            //     generalInvoiceInfo: GeneralInvoiceInfo(
            //       creationDate: DateTime.now().add(Duration(days: 6)),
            //       dueDate: DateTime.now().add(Duration(days: 13)),
            //       invoiceNumber: 'INV004',
            //     ),
            //   ),
            //   InvoicesRecord(
            //     invoiceType: 1,
            //     generalInvoiceInfo: GeneralInvoiceInfo(
            //       creationDate: DateTime.now().add(Duration(days: 6)),
            //       dueDate: DateTime.now().add(Duration(days: 13)),
            //       invoiceNumber: 'INV004',
            //     ),
            //   ),
            //   InvoicesRecord(
            //     invoiceType: 1,
            //     generalInvoiceInfo: GeneralInvoiceInfo(
            //       creationDate: DateTime.now().add(Duration(days: 6)),
            //       dueDate: DateTime.now().add(Duration(days: 13)),
            //       invoiceNumber: 'INV004',
            //     ),
            //   ),
            //   InvoicesRecord(
            //     invoiceType: 1,
            //     generalInvoiceInfo: GeneralInvoiceInfo(
            //       creationDate: DateTime.now().add(Duration(days: 9)),
            //       dueDate: DateTime.now().add(Duration(days: 18)),
            //       invoiceNumber: 'INV005',
            //     ),
            //   ),
            //   InvoicesRecord(
            //     invoiceType: 1,
            //     generalInvoiceInfo: GeneralInvoiceInfo(
            //       creationDate: DateTime.now().add(Duration(days: 12)),
            //       dueDate: DateTime.now().add(Duration(days: 22)),
            //       invoiceNumber: 'INV006',
            //     ),
            //   ),
            //   // Add more InvoicesRecord instances as needed
            // ],
          ),
          GeneratePDF(),
          ProductChart(),
          Tab7(),
          Tab8(),
          Tab9(),
          Tab10(),
        ],
      ),
    );
  }


}
