import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'package:http/http.dart' as http;

class GeneratePDF extends StatefulWidget {
  @override
  _GeneratePDFState createState() => _GeneratePDFState();
}

class _GeneratePDFState extends State<GeneratePDF> {
  final _formKey = GlobalKey<FormState>();
  bool _isLandscape = false;
  bool _showLogo = true;
  bool _showPaymentMethods = true;
  bool _showTermsAndConditions = true;
  bool _showDiscountPercentageColumn = true;
  bool _showDiscountAmountColumn = true;
  bool _showTaxPercentageColumn = true;
  bool _showTaxAmountColumn = true;
  bool _showSignature = true;
  PdfPageFormat _pageFormat = PdfPageFormat.a4;

  List<List<String>> products = [
    ['1', 'Product A', '2', '500.00', '10%', '45.00', '9%', '90.00', '979.80'],
    ['2', 'Product B', '1', '300.00', '5%', '15.00', '9%', '27.00', '312.15'],
    ['3', 'Product C', '3', '150.00', '0%', '0.00', '9%', '40.50', '490.50'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Generator Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              DropdownButtonFormField<PdfPageFormat>(
                value: _pageFormat,
                decoration: InputDecoration(labelText: 'Page Size'),
                items: <PdfPageFormat>[
                  PdfPageFormat.a3,
                  PdfPageFormat.a4,
                  PdfPageFormat.a5,
                  PdfPageFormat.letter,
                  PdfPageFormat.legal,
                ].map<DropdownMenuItem<PdfPageFormat>>((PdfPageFormat value) {
                  return DropdownMenuItem<PdfPageFormat>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
                onChanged: (PdfPageFormat? newValue) {
                  setState(() {
                    _pageFormat = newValue!;
                  });
                },
              ),
              CheckboxListTile(
                title: Text('Landscape'),
                value: _isLandscape,
                onChanged: (bool? value) {
                  setState(() {
                    _isLandscape = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: Text('Show Logo'),
                value: _showLogo,
                onChanged: (bool? value) {
                  setState(() {
                    _showLogo = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: Text('Show Payment Methods'),
                value: _showPaymentMethods,
                onChanged: (bool? value) {
                  setState(() {
                    _showPaymentMethods = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: Text('Show Terms and Conditions'),
                value: _showTermsAndConditions,
                onChanged: (bool? value) {
                  setState(() {
                    _showTermsAndConditions = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: Text('Show Discount Percentage Column'),
                value: _showDiscountPercentageColumn,
                onChanged: (bool? value) {
                  setState(() {
                    _showDiscountPercentageColumn = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: Text('Show Discount Amount Column'),
                value: _showDiscountAmountColumn,
                onChanged: (bool? value) {
                  setState(() {
                    _showDiscountAmountColumn = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: Text('Show Tax Percentage Column'),
                value: _showTaxPercentageColumn,
                onChanged: (bool? value) {
                  setState(() {
                    _showTaxPercentageColumn = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: Text('Show Tax Amount Column'),
                value: _showTaxAmountColumn,
                onChanged: (bool? value) {
                  setState(() {
                    _showTaxAmountColumn = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: Text('Show Signature'),
                value: _showSignature,
                onChanged: (bool? value) {
                  setState(() {
                    _showSignature = value!;
                  });
                },
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Item ${index + 1}'),
                    subtitle: Text(products[index].join(', ')),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          products.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Add Product (comma separated values)'),
                onFieldSubmitted: (value) {
                  setState(() {
                    products.add(value.split(','));
                  });
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  await _generatePdf(context, products);
                },
                child: Text('Generate PDF'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.teal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context, List<List<String>> products) async {
    try {
      final pdf = pw.Document();
      final fontData = await rootBundle.load("fonts/OpenSans-Regular.ttf");
      final ttf = pw.Font.ttf(fontData.buffer.asByteData());

      double discountTotal = 0;
      double taxTotal = 0;
      double priceTotal = 0;

      for (var product in products) {
        discountTotal += double.parse(product[5]);
        taxTotal += double.parse(product[7]);
        priceTotal += double.parse(product[8]);
      }

      final signatureImage = await _loadNetworkImage('https://img.icons8.com/avantgarde/100/signature.png');

      final buyerName = 'Ali Rezaei';
      final buyerAddress = 'Isfahan, Hafez Street, No. 456';
      final buyerPhone = '031-87654321';
      final buyerEmail = 'ali.rezaei@example.com';
      final sellerName = 'Sample Company';
      final sellerAddress = 'Tehran, Valiasr Street, No. 123';
      final sellerPhone = '021-12345678';
      final sellerEmail = 'info@example.com';
      final termsAndConditions = 'Payment within 15 days.\nAfter-sales service for 1 year.\nReturn within 7 days with invoice.';
      final paymentMethods = 'Bank Transfer\nCredit Card\nOnline Payment';

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: _isLandscape ? _pageFormat.landscape : _pageFormat,
            margin: pw.EdgeInsets.all(32),
            theme: pw.ThemeData.withFont(
              base: ttf,
            ),
            buildBackground: (context) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Stack(
                children: [
                  pw.Positioned(
                    top: -100,
                    left: -100,
                    child: pw.Container(
                      width: 300,
                      height: 300,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.teal200,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                  ),
                  pw.Positioned(
                    bottom: -150,
                    right: -150,
                    child: pw.Container(
                      width: 400,
                      height: 400,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange200,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                  ),
                  pw.Positioned(
                    top: 0,
                    left: 0,
                    child: pw.Container(
                      width: 200,
                      height: 200,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.teal50,
                        borderRadius: pw.BorderRadius.only(
                          bottomRight: pw.Radius.circular(100),
                        ),
                      ),
                    ),
                  ),
                  pw.Positioned(
                    bottom: 0,
                    right: 0,
                    child: pw.Container(
                      width: 200,
                      height: 200,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.teal50,
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(100),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          header: (pw.Context context) {
            return pw.Container(
              margin: pw.EdgeInsets.only(bottom: 16),
              padding: pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.teal900,
                borderRadius: pw.BorderRadius.circular(8), // Rounded corners
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  if (_showLogo)
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 50,
                          height: 50,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            shape: pw.BoxShape.circle,
                          ),
                          child: pw.Center(
                            child: pw.Text('LOGO', style: pw.TextStyle(fontSize: 10, color: PdfColors.teal900)),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                      ],
                    ),
                  pw.Text('INVOICE', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Number: INV-2024-001', style: pw.TextStyle(fontSize: 12, color: PdfColors.white)),
                      pw.Text('Issue Date: 2024-06-30', style: pw.TextStyle(fontSize: 12, color: PdfColors.white)),
                      pw.Text('Due Date: 2024-07-15', style: pw.TextStyle(fontSize: 12, color: PdfColors.white)),
                    ],
                  ),
                ],
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              padding: pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.teal900,
                borderRadius: pw.BorderRadius.circular(8), // Rounded corners
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (_showTermsAndConditions && termsAndConditions.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(height: 8),
                          pw.Text('Terms and Conditions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                          pw.Text(termsAndConditions, style: pw.TextStyle(color: PdfColors.white)),
                        ],
                      ),
                    ),
                  if (_showSignature)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.SizedBox(height: 32),
                        pw.Container(
                          width: 100,
                          height: 50,
                          child: pw.Image(pw.MemoryImage(signatureImage)),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
          build: (pw.Context context) {
            return [
              _buildSellerBuyerInfo(
                buyerName,
                buyerAddress,
                buyerPhone,
                buyerEmail,
                sellerName,
                sellerAddress,
                sellerPhone,
                sellerEmail,
              ),
              pw.SizedBox(height: 16),
              _buildProductTable(products, discountTotal, taxTotal, priceTotal),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Sub Total: 200.00 USD', style: pw.TextStyle(color: PdfColors.black)),
                      if (_showTermsAndConditions && termsAndConditions.isNotEmpty)
                        pw.Text('Invoice Level Discount: 200.00 USD', style: pw.TextStyle(color: PdfColors.black)),
                      if (_showTermsAndConditions && termsAndConditions.isNotEmpty)
                        pw.Text('Invoice Level Tax: 174.00 USD', style: pw.TextStyle(color: PdfColors.black)),
                      pw.Text('Final Total: 3,691.55 USD', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    ],
                  ),
                  if (_showPaymentMethods && paymentMethods.isNotEmpty)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Payment Methods:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                        pw.Text(paymentMethods, style: pw.TextStyle(color: PdfColors.black)),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 16),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  pw.Widget _buildSellerBuyerInfo(
      String buyerName,
      String buyerAddress,
      String buyerPhone,
      String buyerEmail,
      String sellerName,
      String sellerAddress,
      String sellerPhone,
      String sellerEmail,
      ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal50,
        borderRadius: pw.BorderRadius.circular(8), // Rounded corners
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Seller Information:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                pw.Text('Company: $sellerName', style: pw.TextStyle(color: PdfColors.black)),
                pw.Text('Address: $sellerAddress', style: pw.TextStyle(color: PdfColors.black)),
                pw.Text('Phone: $sellerPhone', style: pw.TextStyle(color: PdfColors.black)),
                pw.Text('Email: $sellerEmail', style: pw.TextStyle(color: PdfColors.black)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Buyer Information:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                pw.Text('Name: $buyerName', style: pw.TextStyle(color: PdfColors.black)),
                pw.Text('Address: $buyerAddress', style: pw.TextStyle(color: PdfColors.black)),
                pw.Text('Phone: $buyerPhone', style: pw.TextStyle(color: PdfColors.black)),
                pw.Text('Email: $buyerEmail', style: pw.TextStyle(color: PdfColors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProductTable(List<List<String>> products, double discountTotal, double taxTotal, double priceTotal) {
    const int rowsPerPage = 20;
    List<pw.TableRow> rows = [_buildTableHeader()];
    for (int i = 0; i < products.length; i++) {
      if (i % rowsPerPage == 0 && i != 0) {
        rows.add(_buildTableFooter(discountTotal, taxTotal, priceTotal));
        rows.add(pw.TableRow(children: [pw.SizedBox(height: 20)])); // Add space between pages
        rows.add(_buildTableHeader());
      }
      rows.add(pw.TableRow(
        children: _buildTableRow(products[i]),
      ));
    }
    if (products.length % rowsPerPage != 0) {
      rows.add(_buildTableFooter(discountTotal, taxTotal, priceTotal));
    }
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8), // Rounded corners for the whole table
        border: pw.Border.all(color: PdfColors.teal900, width: 0.5),
      ),
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.teal900, width: 0.5),
        children: rows,
      ),
    );
  }

  List<pw.Widget> _buildTableRow(List<String> product) {
    List<pw.Widget> cells = [
      pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.all(2),
        child: pw.Text(product[0], textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
      ),
      pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.all(2),
        child: pw.Text(product[1], textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
      ),
      pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.all(2),
        child: pw.Text(product[2], textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
      ),
      pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.all(2),
        child: pw.Text(product[3], textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
      ),
    ];

    if (_showDiscountPercentageColumn) {
      cells.add(
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(2),
          child: pw.Text(product[4], textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
        ),
      );
    }

    if (_showDiscountAmountColumn) {
      cells.add(
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(2),
          child: pw.Text(product[5], textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
        ),
      );
    }

    if (_showTaxPercentageColumn) {
      cells.add(
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(2),
          child: pw.Text(product[6], textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
        ),
      );
    }

    if (_showTaxAmountColumn) {
      cells.add(
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(2),
          child: pw.Text(product[7], textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
        ),
      );
    }

    cells.add(
      pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.all(2),
        child: pw.Text(product[8], textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
      ),
    );

    return cells;
  }

  pw.TableRow _buildTableHeader() {
    List<pw.Widget> headers = [
      pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text('#', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      ),
      pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text('Prod', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      ),
      pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text('Qty', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      ),
      pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text('U.Price', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      ),
    ];

    if (_showDiscountPercentageColumn) {
      headers.add(
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('Disc %', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      );
    }

    if (_showDiscountAmountColumn) {
      headers.add(
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('Disc Amt', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      );
    }

    if (_showTaxPercentageColumn) {
      headers.add(
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('Tax %', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      );
    }

    if (_showTaxAmountColumn) {
      headers.add(
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('Tax Amt', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      );
    }

    headers.add(
      pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text('T.Price', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      ),
    );

    return pw.TableRow(children: headers);
  }

  pw.TableRow _buildTableFooter(double discountTotal, double taxTotal, double priceTotal) {
    List<pw.Widget> footers = [
      pw.Container(),
      pw.Container(),
      pw.Container(),
      pw.Container(),
    ];

    if (_showDiscountPercentageColumn) {
      footers.add(
        pw.Container(),
      );
    }

    if (_showDiscountAmountColumn) {
      footers.add(
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('${discountTotal.toStringAsFixed(2)}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
        ),
      );
    }

    if (_showTaxPercentageColumn) {
      footers.add(
        pw.Container(),
      );
    }

    if (_showTaxAmountColumn) {
      footers.add(
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('${taxTotal.toStringAsFixed(2)}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
        ),
      );
    }

    footers.add(
      pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text('${priceTotal.toStringAsFixed(2)}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
      ),
    );

    return pw.TableRow(children: footers);
  }

  Future<Uint8List> _loadImage(String imagePath) async {
    final ByteData data = await rootBundle.load(imagePath);
    return data.buffer.asUint8List();
  }

  Future<Uint8List> _loadNetworkImage(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load network image');
    }
  }
}
