import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class Tab10 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HTML to PDF'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _generatePdf,
          child: Text('Generate PDF'),
        ),
      ),
    );
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    final html = '<h1>Hello World!</h1><p>This is a sample HTML content.</p>';

    final ttf = await rootBundle.load("fonts/OpenSans-Regular.ttf");
    final font = pw.Font.ttf(ttf);

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Text(html, style: pw.TextStyle(font: font)),
        ),
      ),
    );

    final Uint8List bytes = await pdf.save();

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
    );
  }
}
