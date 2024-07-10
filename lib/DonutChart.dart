import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Product Chart')),
        body: Center(
          child: ProductChart(),
        ),
      ),
    );
  }
}

class ProductChart extends StatefulWidget {
  @override
  _ProductChartState createState() => _ProductChartState();
}

class _ProductChartState extends State<ProductChart> {
  int? _selectedIndex;
  final Set<int> _hiddenIndices = {};

  void _onProductTap(int index) {
    setState(() {
      if (_selectedIndex == index) {
        _selectedIndex = null; // Deselect if the same product is tapped
      } else {
        _selectedIndex = index;
      }
    });
  }

  void _onOutsideTap() {
    setState(() {
      _selectedIndex = null; // Deselect if clicked outside the list
    });
  }

  void _onPinTap(int index) {
    setState(() {
      if (_hiddenIndices.contains(index)) {
        _hiddenIndices.remove(index);
      } else {
        _hiddenIndices.add(index);
      }
      _selectedIndex = null; // Deselect the item when pinned
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onOutsideTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 32, 8, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 250,
                maxHeight: 250,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: GestureDetector(
                  onTap: () {}, // To prevent tap on chart to clear selection
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        painter: ProductPainter(selectedIndex: _selectedIndex, hiddenIndices: _hiddenIndices),
                        size: Size.infinite,
                      ),
                      if (_selectedIndex != null && !_hiddenIndices.contains(_selectedIndex))
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedPositioned(
                              duration: Duration(milliseconds: 300),
                              child: Image.network(
                                ProductPainter.products[_selectedIndex!].imageUrl,
                                width: 64,
                                height: 64,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Invoices: ${ProductPainter.products[_selectedIndex!].invoiceCount}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Total: \$${ProductPainter.products[_selectedIndex!].totalAmount}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Top Products',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Product Name',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                Text(
                  'Count',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                SizedBox(width: 8),
                Text(
                  'Percentage',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
            Divider(thickness: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: ProductPainter.products.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var product = entry.value;
                    bool isHidden = _hiddenIndices.contains(idx);
                    return GestureDetector(
                      onTap: () => _onProductTap(idx),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            color: _selectedIndex == idx ? Colors.grey[300] : Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 8.0), // Padding inside the container
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                children: [
                                  if (_selectedIndex == idx)
                                    IconButton(
                                      icon: Icon(
                                        isHidden ? Icons.push_pin : Icons.push_pin_outlined,
                                        color: Colors.black,
                                      ),
                                      onPressed: () => _onPinTap(idx),
                                    ),
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: product.color,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: AnimatedDefaultTextStyle(
                                      duration: Duration(milliseconds: 300),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedIndex == idx ? Colors.black : Colors.black87,
                                        decoration: isHidden ? TextDecoration.lineThrough : TextDecoration.none,
                                      ),
                                      child: Text(product.name),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${product.count}',
                                            style: TextStyle(fontSize: 14, color: Colors.black87),
                                          ),
                                          SizedBox(width: 8),
                                          AnimatedContainer(
                                            duration: Duration(milliseconds: 300),
                                            decoration: BoxDecoration(
                                              color: _selectedIndex == idx ? Colors.grey[400] : Colors.grey[200],
                                              borderRadius: BorderRadius.circular(4.0),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                            child: Text(
                                              '(${(product.count / ProductPainter.totalProducts(hiddenIndices: _hiddenIndices) * 100).toStringAsFixed(1)}%)',
                                              style: TextStyle(fontSize: 14, color: Colors.black54),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Divider(thickness: 1), // Divider under each item
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductPainter extends CustomPainter {
  final int? selectedIndex;
  final Set<int> hiddenIndices;

  ProductPainter({required this.selectedIndex, required this.hiddenIndices});

  static final List<Product> products = [
    Product(name: 'Product 1', count: 100, invoiceCount: 50, totalAmount: 5000, imageUrl: 'https://img.icons8.com/arcade/64/fast-moving-consumer-goods.png', color: Colors.red),
    Product(name: 'Product 2', count: 90, invoiceCount: 45, totalAmount: 4500, imageUrl: 'https://img.icons8.com/arcade/64/fast-moving-consumer-goods.png', color: Colors.blue),
    Product(name: 'Product 3', count: 80, invoiceCount: 40, totalAmount: 4000, imageUrl: 'https://img.icons8.com/arcade/64/fast-moving-consumer-goods.png', color: Colors.green),
    Product(name: 'Product 4', count: 70, invoiceCount: 35, totalAmount: 3500, imageUrl: 'https://img.icons8.com/arcade/64/fast-moving-consumer-goods.png', color: Colors.orange),
    Product(name: 'Product 5', count: 60, invoiceCount: 30, totalAmount: 3000, imageUrl: 'https://img.icons8.com/arcade/64/fast-moving-consumer-goods.png', color: Colors.purple),
    Product(name: 'Product 6', count: 50, invoiceCount: 25, totalAmount: 2500, imageUrl: 'https://img.icons8.com/arcade/64/fast-moving-consumer-goods.png', color: Colors.yellow),
    Product(name: 'Product 7', count: 40, invoiceCount: 20, totalAmount: 2000, imageUrl: 'https://img.icons8.com/arcade/64/fast-moving-consumer-goods.png', color: Colors.cyan),
    Product(name: 'Product 8', count: 30, invoiceCount: 15, totalAmount: 1500, imageUrl: 'https://img.icons8.com/arcade/64/fast-moving-consumer-goods.png', color: Colors.pink),
    Product(name: 'Product 9', count: 20, invoiceCount: 10, totalAmount: 1000, imageUrl: 'https://img.icons8.com/arcade/64/fast-moving-consumer-goods.png', color: Colors.lime),
    Product(name: 'Product 10', count: 10, invoiceCount: 5, totalAmount: 500, imageUrl: 'https://img.icons8.com/arcade/64/fast-moving-consumer-goods.png', color: Colors.indigo),
  ];

  static double totalProducts({required Set<int> hiddenIndices}) => products.fold(0, (sum, item) {
    int index = products.indexOf(item);
    if (hiddenIndices.contains(index)) {
      return sum;
    }
    return sum + item.count;
  });

  @override
  void paint(Canvas canvas, Size size) {
    double totalProducts = ProductPainter.totalProducts(hiddenIndices: hiddenIndices);
    double startAngle = -3.14 / 2;
    double radius = size.width / 2;
    double innerRadius = radius * 0.85;

    Rect rect = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: radius);

    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius - innerRadius
      ..strokeCap = StrokeCap.butt;

    Paint selectedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (radius - innerRadius) + 8
      ..strokeCap = StrokeCap.butt;

    for (var i = 0; i < products.length; i++) {
      if (hiddenIndices.contains(i)) {
        continue;
      }
      var product = products[i];
      double sweepAngle = (product.count / totalProducts) * 2 * 3.14;
      paint.color = product.color.withOpacity(selectedIndex == null || selectedIndex == i ? 1.0 : 0.3);
      selectedPaint.color = product.color.withOpacity(selectedIndex == null || selectedIndex == i ? 1.0 : 0.3);
      canvas.drawArc(rect, startAngle, sweepAngle - 0.01, false, selectedIndex == i ? selectedPaint : paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Product {
  final String name;
  final int count;
  final int invoiceCount;
  final double totalAmount;
  final String imageUrl;
  final Color color;

  Product({
    required this.name,
    required this.count,
    required this.invoiceCount,
    required this.totalAmount,
    required this.imageUrl,
    required this.color,
  });
}
