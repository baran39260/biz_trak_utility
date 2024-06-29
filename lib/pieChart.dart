import 'package:flutter/material.dart';
import 'dart:math';

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
  List<Item> items = [
    Item('Item 1', 10, 5, 100.0, 'https://via.placeholder.com/60'),
    Item('Item 2', 20, 3, 200.0, 'https://via.placeholder.com/60'),
    Item('Item 3', 30, 8, 300.0, 'https://via.placeholder.com/60'),
    Item('Item 4', 40, 2, 400.0, 'https://via.placeholder.com/60'),
  ];

  List<Item> filteredItems = [];
  late AnimationController _controller;
  late Animation<double> _animation;
  String sortBy = 'name';
  String searchQuery = '';

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
    filteredItems = items;
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

  void filterItems(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredItems = items;
      } else {
        filteredItems = items
            .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      sortItems();
    });
  }

  void toggleItemSelection(Item item) {
    setState(() {
      item.isSelected = !item.isSelected;
      _controller.reset();
      _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            size: Size(300, 300),
            painter: PieChartPainter(items, _animation.value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Search',
                  border: OutlineInputBorder(),
                ),
                onChanged: filterItems,
              ),
              SizedBox(height: 8),
              Row(
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
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: items.map((item) {
                return GestureDetector(
                  onTap: () => toggleItemSelection(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Chip(
                      label: Text(
                        item.name,
                        style: TextStyle(
                          decoration: item.isSelected ? TextDecoration.none : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
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

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (var item in items) {
      if (!item.isSelected) continue;

      final sweepAngle = (item.sales / total) * 2 * pi * animationValue;
      paint.color = Colors.primaries[items.indexOf(item) % Colors.primaries.length];

      canvas.drawArc(
        Rect.fromLTWH(0, 0, size.width, size.height),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      final radius = size.width / 2;
      final x = radius + radius * cos(startAngle + sweepAngle / 2) / 2;
      final y = radius + radius * sin(startAngle + sweepAngle / 2) / 2;

      final percent = (item.sales / total * 100).toStringAsFixed(1) + '%';
      textPainter.text = TextSpan(
        text: percent,
        style: TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));

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
        return Card(
          elevation: 3,
          margin: EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Image.network(
                  item.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Sales: ${item.sales}'),
                      Text('Invoices: ${item.invoices}'),
                      Text('Total Amount: \$${item.totalAmount.toStringAsFixed(2)}'),
                      SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: item.sales / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
