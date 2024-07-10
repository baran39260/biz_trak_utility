import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';

class Item {
  String name;
  int sales;
  int invoices;
  double totalAmount;
  String imageUrl;
  bool isSelected;

  Item(this.name, this.sales, this.invoices, this.totalAmount, this.imageUrl, {this.isSelected = true});
}

class PieChartScreen extends StatefulWidget {
  @override
  _PieChartScreenState createState() => _PieChartScreenState();
}

class _PieChartScreenState extends State<PieChartScreen> with SingleTickerProviderStateMixin {
  List<Item> items = List.generate(
    10,
        (index) => Item(
      'Item ${index + 1}',
      Random().nextInt(100),
      Random().nextInt(10),
      Random().nextDouble() * 1000,
      'https://via.placeholder.com/60',
    ),
  );

  List<Item> filteredItems = [];
  late AnimationController _controller;
  late Animation<double> _animation;
  String sortBy = 'name';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..addListener(() {
      setState(() {});
    });
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    filteredItems = List.from(items);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void sortItems() {
    setState(() {
      if (sortBy == 'name') {
        filteredItems.sort((a, b) => a.name.compareTo(b.name));
      } else if (sortBy == 'sales') {
        filteredItems.sort((a, b) => b.sales.compareTo(a.sales));
      } else if (sortBy == 'invoices') {
        filteredItems.sort((a, b) => b.invoices.compareTo(a.invoices));
      } else if (sortBy == 'totalAmount') {
        filteredItems.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      }
    });
  }

  void toggleItemSelection(Item item) {
    setState(() {
      item.isSelected = !item.isSelected;
      _controller.reset();
      _controller.forward();
    });
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    final image = await _capturePng();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(pw.MemoryImage(image)),
          );
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/example.pdf");
      await file.writeAsBytes(await pdf.save());
      print("PDF saved to ${file.path}");
    } catch (e) {
      print("Error saving PDF: $e");
    }
  }

  Future<Uint8List> _capturePng() async {
    final boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  final GlobalKey _globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RepaintBoundary(
                  key: _globalKey,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    width: 300,
                    height: 300,
                    child: CustomPaint(
                      painter: PieChartPainter(items, _animation.value),
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.map((item) {
                    return GestureDetector(
                      onTap: () => toggleItemSelection(item),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            color: item.isSelected
                                ? Colors.primaries[items.indexOf(item) % Colors.primaries.length]
                                : Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text(
                            item.name,
                            style: TextStyle(
                              color: item.isSelected
                                  ? Colors.primaries[items.indexOf(item) % Colors.primaries.length]
                                  : Colors.grey,
                              decoration: item.isSelected ? TextDecoration.none : TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sort by:',
                style: TextStyle(fontSize: 16),
              ),
              DropdownButton<String>(
                value: sortBy,
                items: <String>['name', 'sales', 'invoices', 'totalAmount']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    sortBy = newValue!;
                    sortItems();
                  });
                },
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: _generatePdf,
          child: Text('Generate PDF'),
        ),
        Expanded(
          child: ItemDetails(filteredItems),
        ),
      ],
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<Item> items;
  final double animationValue;

  PieChartPainter(this.items, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    double total = items.fold(0, (sum, item) => sum + (item.isSelected ? item.sales : 0)).toDouble();
    double startAngle = -pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.grey.shade300
      ..strokeWidth = 2.0;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final radius = min(size.width, size.height) / 2;

    // Draw outline
    canvas.drawCircle(Offset(radius, radius), radius, outlinePaint);

    for (var item in items) {
      if (!item.isSelected) continue;

      final sweepAngle = (item.sales / total) * 2 * pi * animationValue;
      paint.color = Colors.primaries[items.indexOf(item) % Colors.primaries.length];

      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      final middleAngle = startAngle + sweepAngle / 2;
      final isSmallSlice = sweepAngle < 0.2;
      final x = radius + radius * cos(middleAngle) * 0.7;
      final y = radius + radius * sin(middleAngle) * 0.7;

      final percent = (item.sales / total * 100).toStringAsFixed(1) + '%';

      if (isSmallSlice) {
        // Draw the curved line for small slices
        final path = Path();
        path.moveTo(x, y);
        final controlX = radius + radius * cos(middleAngle) * 0.85;
        final controlY = radius + radius * sin(middleAngle) * 0.85;
        final endX = radius + radius * cos(middleAngle) * 1.1;
        final endY = radius + radius * sin(middleAngle) * 1.1;
        path.quadraticBezierTo(controlX, controlY, endX, endY);
        canvas.drawPath(path, outlinePaint);

        textPainter.text = TextSpan(
          text: percent,
          style: TextStyle(
            fontSize: 10,
            color: Colors.black,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(endX, endY));
      } else {
        // Draw the text inside the slice for larger slices
        textPainter.text = TextSpan(
          text: percent,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ItemDetails extends StatelessWidget {
  final List<Item> items;

  ItemDetails(this.items);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(4.0, 0.0, 0.0, 0.0),
                      child: Container(
                        width: 58.0,
                        height: 58.0,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.background,
                          borderRadius: BorderRadius.circular(27.0),
                        ),
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            item.imageUrl,
                            width: 48.0,
                            height: 48.0,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
                        child: Container(
                          height: 70.0,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.name,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 13.0,
                                      letterSpacing: 0.0,
                                    ),
                                  ),
                                  Text(
                                    '\$${item.totalAmount.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 13.0,
                                      letterSpacing: 0.0,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: item.sales.toString(),
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontSize: 13.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' inv',
                                          style: TextStyle(
                                            fontSize: 11.0,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' - ',
                                          style: TextStyle(
                                            fontSize: 13.0,
                                          ),
                                        ),
                                        TextSpan(
                                          text: item.invoices.toString(),
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.0,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' units',
                                          style: TextStyle(
                                            fontSize: 11.0,
                                          ),
                                        ),
                                      ],
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        letterSpacing: 0.0,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\$${(item.totalAmount - item.sales * item.invoices).toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.secondary,
                                      fontSize: 12.0,
                                      letterSpacing: 0.0,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(4.0, 4.0, 4.0, 0.0),
                                        child: LinearProgressIndicator(
                                          value: item.sales / 100,
                                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}