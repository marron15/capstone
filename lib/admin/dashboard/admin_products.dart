import 'package:flutter/material.dart';
import '../modal/new_products.dart';
import '../sidenav.dart';
import '../services/api_service.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../excel/excel_product_export.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final List<Product> products = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showArchived = false;
  final List<int> _productIds = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final bool archived = _showArchived;
    final list =
        archived
            ? await ApiService.getProductsByStatus('inactive')
            : await ApiService.getProductsByStatus('active');
    setState(() {
      products
        ..clear()
        ..addAll(
          list.map((row) {
            final String name = (row['name'] ?? '').toString();
            final String description = (row['description'] ?? '').toString();
            final String img = (row['img'] ?? '').toString();
            Uint8List? bytes;
            String? url;
            try {
              if (img.startsWith('uploads/') || img.startsWith('http')) {
                url =
                    img.startsWith('http')
                        ? img
                        : '${ApiService.productImageProxyEndpoint}?path=$img';
              } else if (img.isNotEmpty) {
                final String data =
                    img.contains(',') ? img.split(',').last : img;
                bytes = Uint8List.fromList(base64.decode(data));
              }
            } catch (_) {
              bytes = null;
            }
            return Product(
              name: name,
              price: double.tryParse((row['price'] ?? '0').toString()) ?? 0.0,
              description: description,
              imageBytes: bytes,
              imageFileName: 'image',
              imageUrl: url,
            );
          }),
        );
      _productIds
        ..clear()
        ..addAll(
          list.map((row) {
            final dynamic v =
                row['id'] ?? row['product_id'] ?? row['productId'];
            final String s = (v ?? '0').toString();
            return int.tryParse(s) ?? 0;
          }),
        );
    });
  }

  List<Product> _visibleProducts() {
    final String q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return products;
    return products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();
  }

  void _showAddProductDialog({Product? product, int? index}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddProductModal(
          onProductAdded: (Product newProduct) {
            setState(() {
              if (product != null && index != null) {
                products[index] = newProduct;
              } else {
                products.add(newProduct);
              }
            });
          },
          initialProduct: product,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      appBar: AppBar(
        title: const Center(child: Text('Products Management')),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: const SideNav(),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Products',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 560,
                        height: 42,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Search',
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 20,
                              color: Colors.black54,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.black26,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed:
                            () => exportProductsToExcel(
                              context,
                              _visibleProducts(),
                            ),
                        icon: const Icon(
                          Icons.table_chart_rounded,
                          color: Colors.teal,
                          size: 20,
                        ),
                        label: const Text('Export'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Colors.black26),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ).copyWith(
                          side: WidgetStateProperty.resolveWith(
                            (states) => BorderSide(
                              color:
                                  states.contains(WidgetState.hovered)
                                      ? const Color(0xFFFFA812)
                                      : Colors.black26,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () async {
                          setState(() => _showArchived = !_showArchived);
                          await _fetchProducts();
                        },
                        icon: Icon(
                          _showArchived ? Icons.inventory_2 : Icons.inventory,
                          size: 18,
                        ),
                        label: Text(
                          _showArchived ? 'Show Active' : 'Show Archived',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Colors.black26),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          backgroundColor: Colors.white,
                        ).copyWith(
                          side: WidgetStateProperty.resolveWith(
                            (states) => BorderSide(
                              color:
                                  states.contains(WidgetState.hovered)
                                      ? const Color(0xFFFFA812)
                                      : Colors.black26,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showAddProductDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Product'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 1,
                          side: const BorderSide(color: Colors.black26),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ).copyWith(
                          side: WidgetStateProperty.resolveWith(
                            (states) => BorderSide(
                              color:
                                  states.contains(WidgetState.hovered)
                                      ? const Color(0xFFFFA812)
                                      : Colors.black26,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Row styled like customers (larger text)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Image',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Name',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Description',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,

                              child: Text(
                                'Actions',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Data Rows
                      ..._visibleProducts().asMap().entries.map((entry) {
                        final index = entry.key;
                        final product = entry.value;
                        return Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (_) => Dialog(
                                                child: InteractiveViewer(
                                                  child:
                                                      product.imageUrl != null
                                                          ? Image.network(
                                                            product.imageUrl!,
                                                            fit: BoxFit.contain,
                                                          )
                                                          : Image.memory(
                                                            product.imageBytes ??
                                                                Uint8List(0),
                                                            fit: BoxFit.contain,
                                                          ),
                                                ),
                                              ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child:
                                            product.imageUrl != null
                                                ? Image.network(
                                                  product.imageUrl!,
                                                  width: 64,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                )
                                                : (product.imageBytes != null
                                                    ? Image.memory(
                                                      product.imageBytes!,
                                                      width: 64,
                                                      height: 40,
                                                      fit: BoxFit.cover,
                                                    )
                                                    : const SizedBox(
                                                      width: 64,
                                                      height: 40,
                                                    )),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      product.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      product.description,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: Colors.blue.shade200,
                                          ),
                                        ),
                                        child: IconButton(
                                          onPressed:
                                              () => _showAddProductDialog(
                                                product: product,
                                                index: index,
                                              ),
                                          icon: Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color: Colors.blue.shade700,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          tooltip: 'Edit',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: Colors.orange.shade200,
                                          ),
                                        ),
                                        child: IconButton(
                                          onPressed: () async {
                                            final int id =
                                                (index >= 0 &&
                                                        index <
                                                            _productIds.length)
                                                    ? _productIds[index]
                                                    : 0;
                                            if (id == 0) return;
                                            final bool wasArchived =
                                                _showArchived;
                                            final bool ok =
                                                wasArchived
                                                    ? await ApiService.restoreProduct(
                                                      id,
                                                    )
                                                    : await ApiService.archiveProduct(
                                                      id,
                                                    );
                                            if (ok) {
                                              await _fetchProducts();
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    wasArchived
                                                        ? 'Product restored'
                                                        : 'Product archived',
                                                  ),
                                                  backgroundColor:
                                                      wasArchived
                                                          ? Colors.green
                                                          : Colors.orange,
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    wasArchived
                                                        ? 'Failed to restore product'
                                                        : 'Failed to archive product',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                          icon: Icon(
                                            _showArchived
                                                ? Icons.restore_outlined
                                                : Icons.archive_outlined,
                                            size: 18,
                                            color: Colors.orange,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          tooltip:
                                              _showArchived
                                                  ? 'Restore'
                                                  : 'Archive',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 1, color: Colors.grey.shade200),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Removed bottom FAB per request; use top-right New Product button instead
    );
  }
}
