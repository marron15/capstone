import 'package:flutter/material.dart';
import '../admin/services/api_service.dart';

class TrainersSection extends StatefulWidget {
  final bool isSmallScreen;
  final double screenWidth;

  const TrainersSection({
    Key? key,
    required this.isSmallScreen,
    required this.screenWidth,
  }) : super(key: key);

  @override
  State<TrainersSection> createState() => _TrainersSectionState();
}

class _TrainersSectionState extends State<TrainersSection> {
  final List<Map<String, String>> _trainers = [];
  bool _isLoading = false;
  int _pageIndex = 0;
  int _slideDir = 0;
  PageController? _pageController; // for narrow screens

  @override
  void initState() {
    super.initState();
    _load();
    _pageController = PageController(viewportFraction: 0.88);
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final List<Map<String, String>> list = await ApiService.getAllTrainers();
    // Show only active trainers on the public landing page
    final filtered =
        list
            .where((t) => (t['status'] ?? '').toLowerCase() != 'inactive')
            .toList();
    if (!mounted) return;
    setState(() {
      _trainers
        ..clear()
        ..addAll(filtered);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = widget.isSmallScreen;
    final double screenWidth = widget.screenWidth;
    final double headingFontSize = (isSmallScreen
            ? screenWidth * 0.07
            : screenWidth * 0.045)
        .clamp(22.0, 48.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20.0 : screenWidth * 0.1,
          ),
          child: Center(
            child: Column(
              children: [
                Text(
                  'Trainers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: headingFontSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 28,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Text(
                    'For Inquiries, contact with our Trainers below.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: headingFontSize * 0.65,
                      letterSpacing: 0.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12),
        if (_isLoading)
          const Center(
            child: SizedBox(
              width: 200,
              child: LinearProgressIndicator(minHeight: 2),
            ),
          ),
        if (!_isLoading && _trainers.isEmpty)
          const Center(
            child: Text(
              'No trainers available yet',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        if (_trainers.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              // Show 1 per row on very small, otherwise 4 per page horizontally
              final bool narrow = constraints.maxWidth < 480;
              final int perPage = narrow ? 1 : 4;
              final int totalPages = (_trainers.length / perPage).ceil();
              _pageIndex = _pageIndex.clamp(0, (totalPages - 1).clamp(0, 999));
              final bool canPrev = _pageIndex > 0;
              final bool canNext = _pageIndex < totalPages - 1;

              final int start = _pageIndex * perPage;
              final int endExclusive = (start + perPage).clamp(
                0,
                _trainers.length,
              );
              final List<Map<String, String>> pageItems = _trainers.sublist(
                start,
                endExclusive,
              );

              if (narrow) {
                // Dedicated swipeable PageView on narrow screens
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 20 : screenWidth * 0.08,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: isSmallScreen ? 220 : 240,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _trainers.length,
                          onPageChanged: (i) => setState(() => _pageIndex = i),
                          itemBuilder: (context, i) {
                            final t = _trainers[i];
                            final String first = t['firstName'] ?? '';
                            final String last = t['lastName'] ?? '';
                            final String contact = t['contactNumber'] ?? '';
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 12,
                                vertical: 12,
                              ),
                              child: _TrainerCard(
                                name: '${first.trim()} ${last.trim()}'.trim(),
                                contact: contact,
                                isMobile: true,
                              ),
                            );
                          },
                        ),
                      ),
                      if (_trainers.length > 1) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_trainers.length, (i) {
                            final bool active = i == _pageIndex;
                            return GestureDetector(
                              onTap: () {
                                _pageController?.animateToPage(
                                  i,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: active ? 12 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: active ? Colors.white : Colors.white54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : screenWidth * 0.06,
                ),
                child: Column(
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
                              pageItems.map((t) {
                                final String first = t['firstName'] ?? '';
                                final String last = t['lastName'] ?? '';
                                final String contact = t['contactNumber'] ?? '';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: _TrainerCard(
                                    name:
                                        '${first.trim()} ${last.trim()}'.trim(),
                                    contact: contact,
                                    isMobile: false,
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                    if (totalPages > 1) ...[
                      const SizedBox(height: 14),
                      Center(
                        child: Container(
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
                                  color:
                                      canPrev ? Colors.white : Colors.white38,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
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
                                  color:
                                      canNext ? Colors.white : Colors.white38,
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
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _TrainerCard extends StatefulWidget {
  final String name;
  final String contact;
  final bool isMobile;

  const _TrainerCard({
    required this.name,
    required this.contact,
    this.isMobile = false,
  });

  @override
  State<_TrainerCard> createState() => _TrainerCardState();
}

class _TrainerCardState extends State<_TrainerCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final String name = widget.name;
    final String contact = widget.contact;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = widget.isMobile;

    if (isMobile) {
      // Mobile-optimized layout based on the first image
      final double cardWidth = (screenWidth * 0.9).clamp(280.0, 360.0);
      final double cardHeight = 180;

      return Center(
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white30, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Trainer name - prominent and centered
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Contact info - styled like the first image
              if (contact.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.phone,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        contact,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Desktop/tablet layout
    final bool compact = screenWidth < 420;
    final double cardWidth =
        compact ? (screenWidth * 0.86).clamp(250.0, 340.0) : 320;
    final double nameFont = compact ? 17 : 19;
    final double phoneFont = compact ? 12 : 13.5;
    final EdgeInsets cardPadding = EdgeInsets.symmetric(
      horizontal: compact ? 16 : 18,
      vertical: compact ? 14 : 16,
    );

    return Center(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: SystemMouseCursors.basic,
        child: Container(
          width: cardWidth,
          padding: cardPadding,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0E0E0E), Color(0xFF1B1B1B)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Accent bar (hover only)
              AnimatedOpacity(
                opacity: _isHovering ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: 56,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFA812), Color(0xFFFF7A12)],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: nameFont,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              if (contact.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        contact,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: phoneFont,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// (removed initials helper after refactor)
