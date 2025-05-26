import 'package:flutter/material.dart';
import '../sidenav.dart';

class AdminProductsPage extends StatelessWidget {
  const AdminProductsPage({super.key});

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
        child: Container(
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add product functionality
        },
        backgroundColor: Colors.blue,
        tooltip: 'Add Product',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
    );
  }
}
