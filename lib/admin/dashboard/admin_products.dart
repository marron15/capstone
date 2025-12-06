import 'package:flutter/material.dart';
import '../modal/new_products.dart';
import '../sidenav.dart';
import '../services/api_service.dart';
import 'dart:typed_data';
import 'dart:convert';
// export removed

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
  static const double _drawerWidth = 280;
  bool _navCollapsed = false;

  Widget _buildArchiveEmpty({
    required String title,
    required String helper,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.black.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              helper,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.inventory_2, size: 18),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEFF3FF),
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            final dynamic rawId =
                row['id'] ?? row['product_id'] ?? row['productId'];
            final int parsedId = int.tryParse((rawId ?? '0').toString()) ?? 0;
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
              id: parsedId == 0 ? null : parsedId,
              name: name,
              price: double.tryParse((row['price'] ?? '0').toString()) ?? 0.0,
              description: description,
              imageBytes: bytes,
              imageFileName: 'image',
              imageUrl: url,
              imagePath: img,
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

  Widget _buildMobileProductCard(Product product, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with image and actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      product.imageUrl != null
                          ? Image.network(
                            product.imageUrl!,
                            width: 80,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                          : (product.imageBytes != null
                              ? Image.memory(
                                product.imageBytes!,
                                width: 80,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                              : Container(
                                width: 80,
                                height: 60,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.image_outlined,
                                  color: Colors.grey,
                                  size: 32,
                                ),
                              )),
                ),
                const SizedBox(width: 12),
                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              'ID: ' +
                                  ((index >= 0 && index < _productIds.length)
                                          ? _productIds[index]
                                          : 0)
                                      .toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      const SizedBox.shrink(),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  children: [
                    // Edit button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.blue,
                          size: 18,
                        ),
                        onPressed:
                            () => _showAddProductDialog(
                              product: product,
                              index: index,
                            ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        tooltip: 'Edit Product',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Archive/Restore button
                    Container(
                      decoration: BoxDecoration(
                        color:
                            _showArchived
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              _showArchived
                                  ? Colors.green.shade200
                                  : Colors.orange.shade200,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          final int id =
                              (index >= 0 && index < _productIds.length)
                                  ? _productIds[index]
                                  : 0;
                          if (id == 0) return;
                          final bool wasArchived = _showArchived;
                          final bool ok =
                              wasArchived
                                  ? await ApiService.restoreProduct(id)
                                  : await ApiService.archiveProduct(id);
                          if (ok) {
                            await _fetchProducts();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  wasArchived
                                      ? 'Product restored'
                                      : 'Product archived',
                                ),
                                backgroundColor:
                                    wasArchived ? Colors.green : Colors.orange,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
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
                          color: _showArchived ? Colors.green : Colors.orange,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        tooltip:
                            _showArchived
                                ? 'Restore Product'
                                : 'Archive Product',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog({Product? product, int? index}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final int? productId =
            product?.id ??
            ((index != null && index >= 0 && index < _productIds.length)
                ? _productIds[index]
                : null);
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
          productId: productId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      drawer:
          isMobile
              ? Drawer(
                width: _drawerWidth,
                child: SideNav(
                  width: _drawerWidth,
                  onClose: () => Navigator.of(context).pop(),
                ),
              )
              : null,
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Desktop sidebar - hidden on mobile
            if (!isMobile)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: _navCollapsed ? 0 : _drawerWidth,
                child: SideNav(
                  width: _drawerWidth,
                  onClose: () => setState(() => _navCollapsed = true),
                ),
              ),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                decoration: const BoxDecoration(color: Colors.white),
                child:
                    isMobile
                        ? Column(
                          children: [
                            // Header row with menu button and title
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.transparent,
                              child: Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Open Menu',
                                    onPressed:
                                        () =>
                                            _scaffoldKey.currentState
                                                ?.openDrawer(),
                                    icon: const Icon(Icons.menu),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: const Text(
                                      'Products',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Search bar for mobile
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: SizedBox(
                                height: 36,
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (value) {
                                    setState(() => _searchQuery = value);
                                  },
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search',
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      size: 18,
                                      color: Colors.black54,
                                    ),
                                    suffixIcon:
                                        _searchQuery.isNotEmpty
                                            ? IconButton(
                                              icon: const Icon(
                                                Icons.clear,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(
                                                  () => _searchQuery = '',
                                                );
                                              },
                                            )
                                            : null,
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade400,
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Action buttons for mobile
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              color: Colors.transparent,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // First row with View Archives button
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            setState(
                                              () =>
                                                  _showArchived =
                                                      !_showArchived,
                                            );
                                            await _fetchProducts();
                                          },
                                          icon: Icon(
                                            _showArchived
                                                ? Icons.inventory_2
                                                : Icons.archive,
                                            size: 16,
                                          ),
                                          label: Text(
                                            _showArchived
                                                ? 'View Active'
                                                : 'View Archives',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black87,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ).copyWith(
                                            side:
                                                WidgetStateProperty.resolveWith(
                                                  (states) => BorderSide(
                                                    color:
                                                        states.contains(
                                                              WidgetState
                                                                  .hovered,
                                                            )
                                                            ? const Color(
                                                              0xFFFFA812,
                                                            )
                                                            : Colors.black26,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Second row with New Product button
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              () => _showAddProductDialog(),
                                          icon: const Icon(Icons.add, size: 16),
                                          label: const Text('New Product'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.blue,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ).copyWith(
                                            side:
                                                WidgetStateProperty.resolveWith(
                                                  (states) => BorderSide(
                                                    color:
                                                        states.contains(
                                                              WidgetState
                                                                  .hovered,
                                                            )
                                                            ? const Color(
                                                              0xFFFFA812,
                                                            )
                                                            : Colors.black26,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Mobile product list
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                children:
                                    _visibleProducts().map((product) {
                                      final index = _visibleProducts().indexOf(
                                        product,
                                      );
                                      return _buildMobileProductCard(
                                        product,
                                        index,
                                      );
                                    }).toList(),
                              ),
                            ),
                          ],
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip:
                                            _navCollapsed
                                                ? 'Open Sidebar'
                                                : 'Close Sidebar',
                                        onPressed:
                                            () => setState(
                                              () =>
                                                  _navCollapsed =
                                                      !_navCollapsed,
                                            ),
                                        icon: Icon(
                                          _navCollapsed
                                              ? Icons.menu
                                              : Icons.chevron_left,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
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
                                          onChanged:
                                              (v) => setState(
                                                () => _searchQuery = v,
                                              ),
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.black26,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 0,
                                                ),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Export removed
                                      const Spacer(),
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          setState(
                                            () =>
                                                _showArchived = !_showArchived,
                                          );
                                          await _fetchProducts();
                                        },
                                        icon: Icon(
                                          _showArchived
                                              ? Icons.inventory_2
                                              : Icons.inventory,
                                          size: 18,
                                        ),
                                        label: Text(
                                          _showArchived
                                              ? 'Show Active'
                                              : 'Show Archived',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.black87,
                                          side: const BorderSide(
                                            color: Colors.black26,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
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
                                                  states.contains(
                                                        WidgetState.hovered,
                                                      )
                                                      ? const Color(0xFFFFA812)
                                                      : Colors.black26,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        onPressed:
                                            () => _showAddProductDialog(),
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('New Product'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black87,
                                          elevation: 1,
                                          side: const BorderSide(
                                            color: Colors.black26,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                        ).copyWith(
                                          side: WidgetStateProperty.resolveWith(
                                            (states) => BorderSide(
                                              color:
                                                  states.contains(
                                                        WidgetState.hovered,
                                                      )
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
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
                                        child: Row(
                                          children: const [
                                            SizedBox(
                                              width: 80,
                                              child: Text(
                                                'ID',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
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
                                      if (_showArchived &&
                                          _visibleProducts().isEmpty)
                                        _buildArchiveEmpty(
                                          title: 'No archived products',
                                          helper:
                                              'Archived products will appear here',
                                          actionLabel: 'Show Active Products',
                                          onAction: () async {
                                            setState(
                                              () => _showArchived = false,
                                            );
                                            await _fetchProducts();
                                          },
                                        )
                                      else
                                        ..._visibleProducts().asMap().entries.map((
                                          entry,
                                        ) {
                                          final index = entry.key;
                                          final product = entry.value;
                                          return Column(
                                            children: [
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 80,
                                                    child: Center(
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 6,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFFE6F0FF,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                          border: Border.all(
                                                            color: const Color(
                                                              0xFF90CAF9,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          '#${((index >= 0 && index < _productIds.length) ? _productIds[index] : 0).toString()}',
                                                          style:
                                                              const TextStyle(
                                                                color: Color(
                                                                  0xFF1976D2,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
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
                                                                        product.imageUrl !=
                                                                                null
                                                                            ? Image.network(
                                                                              product.imageUrl!,
                                                                              fit:
                                                                                  BoxFit.contain,
                                                                            )
                                                                            : Image.memory(
                                                                              product.imageBytes ??
                                                                                  Uint8List(
                                                                                    0,
                                                                                  ),
                                                                              fit:
                                                                                  BoxFit.contain,
                                                                            ),
                                                                  ),
                                                                ),
                                                          );
                                                        },
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          child:
                                                              product.imageUrl !=
                                                                      null
                                                                  ? Image.network(
                                                                    product
                                                                        .imageUrl!,
                                                                    width: 64,
                                                                    height: 40,
                                                                    fit:
                                                                        BoxFit
                                                                            .cover,
                                                                  )
                                                                  : (product.imageBytes !=
                                                                          null
                                                                      ? Image.memory(
                                                                        product
                                                                            .imageBytes!,
                                                                        width:
                                                                            64,
                                                                        height:
                                                                            40,
                                                                        fit:
                                                                            BoxFit.cover,
                                                                      )
                                                                      : const SizedBox(
                                                                        width:
                                                                            64,
                                                                        height:
                                                                            40,
                                                                      )),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 3,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 14,
                                                            horizontal: 8,
                                                          ),
                                                      child: Text(
                                                        product.name,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 14,
                                                            horizontal: 8,
                                                          ),
                                                      child: Text(
                                                        product.description,
                                                        textAlign:
                                                            TextAlign.center,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 1,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Container(
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Colors
                                                                    .blue
                                                                    .shade50,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  Colors
                                                                      .blue
                                                                      .shade200,
                                                            ),
                                                          ),
                                                          child: IconButton(
                                                            onPressed:
                                                                () => _showAddProductDialog(
                                                                  product:
                                                                      product,
                                                                  index: index,
                                                                ),
                                                            icon: Icon(
                                                              Icons
                                                                  .edit_outlined,
                                                              size: 18,
                                                              color:
                                                                  Colors
                                                                      .blue
                                                                      .shade700,
                                                            ),
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  8,
                                                                ),
                                                            constraints:
                                                                const BoxConstraints(
                                                                  minWidth: 36,
                                                                  minHeight: 36,
                                                                ),
                                                            tooltip: 'Edit',
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Container(
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Colors
                                                                    .orange
                                                                    .shade50,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  Colors
                                                                      .orange
                                                                      .shade200,
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
                                                              if (id == 0)
                                                                return;
                                                              final bool
                                                              wasArchived =
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
                                                                    backgroundColor:
                                                                        Colors
                                                                            .red,
                                                                  ),
                                                                );
                                                              }
                                                            },
                                                            icon: Icon(
                                                              _showArchived
                                                                  ? Icons
                                                                      .restore_outlined
                                                                  : Icons
                                                                      .archive_outlined,
                                                              size: 18,
                                                              color:
                                                                  Colors.orange,
                                                            ),
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  8,
                                                                ),
                                                            constraints:
                                                                const BoxConstraints(
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
                                              Divider(
                                                height: 1,
                                                color: Colors.grey.shade200,
                                              ),
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
            ),
          ],
        ),
      ),
    );
  }
}
