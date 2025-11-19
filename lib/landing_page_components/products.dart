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

    // Default four items (kept first, always visible)
    final defaults = <_ProductItem>[
      _ProductItem(
        title: 'Whey Protein',
        description: 'Whey protein with vitamins C. Convenient sachets.',
        image: const AssetImage('assets/images/services&products/whey.png'),
      ),
      _ProductItem(
        title: 'Serious Mass',
        description: 'High-calorie mass gainer. 12 lbs, chocolate flavor.',
        image: const AssetImage('assets/images/services&products/mass.png'),
      ),
      _ProductItem(
        title: 'Prothin Creatine',
        description: 'Monohydrate creatine powder. 60 servings.',
        image: const AssetImage('assets/images/services&products/creatine.png'),
      ),
      _ProductItem(
        title: 'Amino 2222 Tabs',
        description: 'Full spectrum blend micronized aminos. 320 tablets.',
        image: const AssetImage('assets/images/services&products/amino.png'),
      ),
    ];

    // Load active products from API and append after defaults
    final apiRows = await ApiService.getProductsByStatus('active');
    final apiItems = <_ProductItem>[];
    for (final row in apiRows) {
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
        _ProductItem(title: title, description: description, image: provider),
      );
    }

    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(defaults)
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
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20.0 : screenWidth * 0.1,
          ),
          child: Center(
            child: Text(
              'Products',
              style: TextStyle(
                color: Colors.white,
                fontSize: (isSmallScreen
                        ? screenWidth * 0.07
                        : screenWidth * 0.045)
                    .clamp(22.0, 48.0),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.03),
        if (_isLoading)
          const SizedBox(
            width: 220,
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (!_isLoading && _items.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final bool narrow = constraints.maxWidth < 480;
              final int perPage = narrow ? 1 : 4;
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
                      child: Row(
                        key: ValueKey<int>(_pageIndex),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            pageItems
                                .map(
                                  (p) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: _FlexibleProductCard(
                                      image: p.image,
                                      title: p.title,
                                      description: p.description,
                                      isSmallScreen: isSmallScreen,
                                      screenWidth: screenWidth,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),
                  if (totalPages > 1) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
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
        SizedBox(height: screenHeight * 0.06),
      ],
    );
  }
}

class _ProductItem {
  final String title;
  final String description;
  final ImageProvider image;
  _ProductItem({
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

  const _FlexibleProductCard({
    required this.image,
    required this.title,
    required this.description,
    required this.isSmallScreen,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    double cardWidth = isSmallScreen ? screenWidth * 0.6 : screenWidth * 0.18;
    cardWidth = cardWidth.clamp(150.0, 260.0);
    return SizedBox(
      width: cardWidth,
      height: 260,
      child: _ProductCard(
        image: image,
        title: title,
        description: description,
        isSmallScreen: isSmallScreen,
        screenWidth: screenWidth,
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ImageProvider image;
  final String title;
  final String description;
  final bool isSmallScreen;
  final double screenWidth;

  const _ProductCard({
    required this.image,
    required this.title,
    required this.description,
    required this.isSmallScreen,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image(
              image: image,
              width: double.infinity,
              height: 260,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            width: double.infinity,
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.black.withAlpha((0.35 * 255).toInt()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: (isSmallScreen
                            ? screenWidth * 0.045
                            : screenWidth * 0.018)
                        .clamp(14.0, 22.0),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (isSmallScreen
                            ? screenWidth * 0.03
                            : screenWidth * 0.012)
                        .clamp(11.0, 16.0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
