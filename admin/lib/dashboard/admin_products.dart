import 'package:flutter/material.dart';
import '../sidenav.dart';
import '../modal/new_products.dart';
import '../card/product_card.dart';
import 'dart:typed_data';

class Product {
  final Uint8List imageBytes;
  final String name;
  final String description;

  Product(
      {required this.imageBytes,
      required this.name,
      required this.description});
}

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final List<Product> _products = [];

  void _addProduct(Uint8List imageBytes, String name, String description) {
    setState(() {
      _products.add(Product(
          imageBytes: imageBytes, name: name, description: description));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SideNav(),
      backgroundColor: const Color(0xFFF6F4FA),
      appBar: AppBar(
        title: const Text('Product Page'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Center(
        child: _products.isEmpty
            ? Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(20),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_bag_outlined,
                        size: 64, color: Colors.blueGrey),
                    SizedBox(height: 16),
                    Text(
                      'No products yet.',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the + button to add your first product!',
                      style: TextStyle(fontSize: 14, color: Colors.black38),
                    ),
                  ],
                ),
              )
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount =
                        (constraints.maxWidth ~/ 260).clamp(1, 4);
                    return GridView.builder(
                      shrinkWrap: true,
                      itemCount: _products.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 0.82,
                      ),
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return ProductCard(
                          imageBytes: product.imageBytes,
                          name: product.name,
                          description: product.description,
                        );
                      },
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddProductModal(
              onSave: _addProduct,
            ),
          );
        },
        backgroundColor: Colors.blue,
        tooltip: 'Add Product',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
    );
  }
}
