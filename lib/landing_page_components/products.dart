import 'package:flutter/material.dart';
import 'dart:convert';
import '../admin/services/api_service.dart';

class ProductsSection extends StatefulWidget {
  final bool isSmallScreen;
  final double screenWidth;
  final double screenHeight;

  const ProductsSection({
    Key? key,
    required this.isSmallScreen,
    required this.screenWidth,
    required this.screenHeight,
  }) : super(key: key);

  @override
  State<ProductsSection> createState() => _ProductsSectionState();
}

class _ProductsSectionState extends State<ProductsSection> {
  final List<_ProductItem> _items = [];
  bool _isLoading = false;
  int _pageIndex = 0;
  int _slideDir = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _isLoading = true);

    final apiRows = await ApiService.getProductsByStatus('active');
    final apiItems = <_ProductItem>[];
    for (final row in apiRows) {
      final dynamic idValue =
          row['id'] ?? row['product_id'] ?? row['productId'];
      final int? productId =
          idValue == null ? null : int.tryParse(idValue.toString());
      final String title = (row['name'] ?? '').toString();
      final String description = (row['description'] ?? '').toString();
      final String img = (row['img'] ?? '').toString();
      ImageProvider? provider;
      try {
        if (img.startsWith('uploads/') || img.startsWith('http')) {
          final String url =
              img.startsWith('http')
                  ? img
                  : '${ApiService.productImageProxyEndpoint}?path=$img';
          provider = NetworkImage(url);
        } else if (img.isNotEmpty) {
          final String data = img.contains(',') ? img.split(',').last : img;
          provider = MemoryImage(base64Decode(data));
        }
      } catch (_) {
        provider = null;
      }
      if (title.isEmpty || description.isEmpty || provider == null) continue;
      apiItems.add(
        _ProductItem(
          productId: productId,
          title: title,
          description: description,
          image: provider,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(apiItems);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Lightweight model note: item model is defined below the State class.

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = widget.isSmallScreen;
    final double screenWidth = widget.screenWidth;
    final double screenHeight = widget.screenHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Center(
            child: Text(
              'Products',
              style: TextStyle(
                color: Colors.white,
                fontSize: (isSmallScreen
                        ? screenWidth * 0.08
                        : screenWidth * 0.04)
                    .clamp(28.0, 56.0),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Explore our high-quality fitness gear and supplements',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 48),
        if (_isLoading)
          const SizedBox(
            width: 220,
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (!_isLoading && _items.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final int perPage =
                  4; // Always 4 per page, letting Wrap construct the 2x2 grid or stack
              final int totalPages = (_items.length / perPage).ceil();
              _pageIndex = _pageIndex.clamp(0, (totalPages - 1).clamp(0, 999));
              final bool canPrev = _pageIndex > 0;
              final bool canNext = _pageIndex < totalPages - 1;

              // Current page items
              final int start = _pageIndex * perPage;
              final int endExclusive = (start + perPage).clamp(
                0,
                _items.length,
              );
              final List<_ProductItem> pageItems = _items.sublist(
                start,
                endExclusive,
              );

              return Column(
                children: [
                  GestureDetector(
                    onHorizontalDragEnd: (details) {
                      final v = details.primaryVelocity ?? 0;
                      if (v < -200 && canNext) {
                        setState(() {
                          _slideDir = 1;
                          _pageIndex += 1;
                        });
                      } else if (v > 200 && canPrev) {
                        setState(() {
                          _slideDir = -1;
                          _pageIndex -= 1;
                        });
                      }
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final begin = Offset(_slideDir.toDouble(), 0);
                        return ClipRect(
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: begin,
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        key: ValueKey<int>(_pageIndex),
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Wrap(
                          spacing: 24, // Horizontal spacing
                          runSpacing: 24, // Vertical spacing
                          alignment: WrapAlignment.center,
                          children:
                              pageItems
                                  .map(
                                    (p) => _FlexibleProductCard(
                                      image: p.image,
                                      title: p.title,
                                      description: p.description,
                                      isSmallScreen: isSmallScreen,
                                      screenWidth: screenWidth,
                                      onTap: null,
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                  ),
                  if (totalPages > 1) ...[
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.55 * 255).toInt()),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.35 * 255).toInt()),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Previous',
                            splashRadius: 18,
                            icon: Icon(
                              Icons.chevron_left,
                              size: 22,
                              color: canPrev ? Colors.white : Colors.white38,
                            ),
                            onPressed:
                                canPrev
                                    ? () => setState(() {
                                      _slideDir = -1;
                                      _pageIndex -= 1;
                                    })
                                    : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '${_pageIndex + 1} / $totalPages',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Next',
                            splashRadius: 18,
                            icon: Icon(
                              Icons.chevron_right,
                              size: 22,
                              color: canNext ? Colors.white : Colors.white38,
                            ),
                            onPressed:
                                canNext
                                    ? () => setState(() {
                                      _slideDir = 1;
                                      _pageIndex += 1;
                                    })
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        if (!_isLoading && _items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No products available yet. Please check back soon!',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        SizedBox(height: screenHeight * 0.06),
      ],
    );
  }
}

class _ProductItem {
  final int? productId;
  final String title;
  final String description;
  final ImageProvider image;
  bool get canReserve => productId != null;
  _ProductItem({
    required this.productId,
    required this.title,
    required this.description,
    required this.image,
  });
}

class _FlexibleProductCard extends StatelessWidget {
  final ImageProvider image;
  final String title;
  final String description;
  final bool isSmallScreen;
  final double screenWidth;
  final VoidCallback? onTap;

  const _FlexibleProductCard({
    required this.image,
    required this.title,
    required this.description,
    required this.isSmallScreen,
    required this.screenWidth,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Medium adaptive width:
    double cardWidth =
        screenWidth >= 1100
            ? (screenWidth * 0.22).clamp(
              240.0,
              320.0,
            ) // 4 in a row on very wide
            : screenWidth >= 700
            ? (screenWidth * 0.42).clamp(250.0, 360.0) // 2x2 on tablet/laptop
            : (screenWidth * 0.85).clamp(240.0, 400.0); // Stacked on mobile

    double cardHeight = screenWidth >= 700 ? 320 : 300;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: _ProductCardInteractive(
        image: image,
        title: title,
        description: description,
        onTap: onTap,
      ),
    );
  }
}

class _ProductCardInteractive extends StatefulWidget {
  final ImageProvider image;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const _ProductCardInteractive({
    required this.image,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  State<_ProductCardInteractive> createState() =>
      _ProductCardInteractiveState();
}

class _ProductCardInteractiveState extends State<_ProductCardInteractive> {
  bool _isHovered = false;

  void _setOnHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
          widget.onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
      onEnter: (_) => _setOnHover(true),
      onExit: (_) => _setOnHover(false),
      child: GestureDetector(
        onTapDown: (_) => _setOnHover(true),
        onTapUp: (_) => _setOnHover(false),
        onTapCancel: () => _setOnHover(false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform:
              Matrix4.identity()..scaleByDouble(
                _isHovered ? 1.02 : 1.0,
                _isHovered ? 1.02 : 1.0,
                1.0,
                1.0,
              ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow:
                _isHovered
                    ? [
                      BoxShadow(
                        color: Colors.black.withAlpha(80),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image(image: widget.image, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(50),
                        Colors.black.withAlpha(200),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _isHovered ? 1.0 : 0.8,
                        child: Text(
                          widget.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
