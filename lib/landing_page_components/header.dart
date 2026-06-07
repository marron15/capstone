import 'package:flutter/material.dart';
import '../services/unified_auth_state.dart';
import '../services/apk_download_button.dart';
import 'sidenav.dart';

// Landing header: transparent over the hero; solid bar once scrolled (sticky).
class MainHeader extends StatelessWidget {
  final bool isScrolled;
  final void Function(String section)? onSectionTap;
  final String? selectedSection;

  const MainHeader({
    super.key,
    this.isScrolled = false,
    this.onSectionTap,
    this.selectedSection,
  });

  /// Top `Padding` for logged-in hero content so it clears the **expanded**
  /// header (must stay in sync with [expandedHeaderHeight] breakpoints below).
  static double loggedInHeroTopPadding(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final double topInset = MediaQuery.paddingOf(context).top;
    final bool isDesktop = width >= 1180;
    final bool isSmallMobile = width < 420;
    final double expandedHeaderHeight =
        isDesktop ? 160 : (isSmallMobile ? 96 : 108);
    return topInset + expandedHeaderHeight + 16;
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double topInset = MediaQuery.of(context).padding.top;
    // Wide enough for full inline nav + branding + actions (was 900 → overflow ~1000px).
    final bool isDesktop = screenSize.width >= 1180;
    final bool isSmallMobile = screenSize.width < 420;
    final double expandedHeaderHeight =
        isDesktop ? 160 : (isSmallMobile ? 96 : 108);
    final double collapsedHeaderHeight =
        isDesktop ? 80 : (isSmallMobile ? 68 : 74);
    final double horizontalPadding =
        isDesktop
            ? (screenSize.width < 1280 ? 24.0 : 40.0)
            : (screenSize.width < 360 ? 12 : (isSmallMobile ? 16 : 20));
    final double topContentPadding =
        isDesktop ? (topInset + 12) : (topInset + 6);
    final double bottomContentPadding = isDesktop ? 12 : 6;

    Future<void> handleLogout() async {
      await unifiedAuthState.logout();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    }

    void openMobileMenu() {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Navigation Menu',
        barrierColor: Colors.black.withValues(alpha: 0.55),
        transitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (dialogContext, _, __) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: SizedBox(
                  width: MediaQuery.of(dialogContext).size.width * 0.82,
                  child: LandingSideNav(
                    onSectionTap: onSectionTap,
                    selectedSection: selectedSection,
                    onProfileTap: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.pushNamed(context, '/customer-profile');
                    },
                    onLogoutTap: () async {
                      Navigator.of(dialogContext).pop();
                      await handleLogout();
                    },
                  ),
                ),
              ),
            ),
          );
        },
        transitionBuilder: (_, animation, __, child) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
          return SlideTransition(position: offsetAnimation, child: child);
        },
      );
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        height:
            (isScrolled ? collapsedHeaderHeight : expandedHeaderHeight) +
            topInset,
        decoration: BoxDecoration(
          color: isScrolled ? const Color(0xFF111111) : Colors.transparent,
          border:
              isScrolled
                  ? const Border(
                    bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
                  )
                  : null,
          boxShadow:
              isScrolled
                  ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topContentPadding,
            horizontalPadding,
            bottomContentPadding,
          ),
          child:
              isDesktop
                  ? SizedBox(
                    width: double.infinity,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: const _BrandLogo(fontSize: 30),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: unifiedAuthState,
                                builder: (context, child) {
                                  if (unifiedAuthState.isCustomerLoggedIn) {
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/customer-profile',
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.account_circle,
                                            color: Colors.white,
                                            size: 45,
                                          ),
                                          tooltip: 'Profile',
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: handleLogout,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red
                                                .withValues(alpha: 0.8),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.logout, size: 16),
                                              SizedBox(width: 6),
                                              Text(
                                                'Logout',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                              const SizedBox(width: 10),
                              const ApkDownloadButton(),
                            ],
                          ),
                        ),
                        // True horizontal center of the header; painted last so
                        // links stay tappable if they overlap the logo strip.
                        Center(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _HeaderNavTextButton(
                                    label: 'Home',
                                    onTap: () => onSectionTap?.call('Home'),
                                  ),
                                  _HeaderNavTextButton(
                                    label: 'Service',
                                    onTap: () => onSectionTap?.call('Service'),
                                  ),
                                  _HeaderNavTextButton(
                                    label: 'Products',
                                    onTap: () => onSectionTap?.call('Products'),
                                  ),
                                  _HeaderNavTextButton(
                                    label: 'Inquiries',
                                    onTap:
                                        () => onSectionTap?.call('Inquiries'),
                                  ),
                                  _HeaderNavTextButton(
                                    label: 'About Us',
                                    onTap: () => onSectionTap?.call('About Us'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: openMobileMenu,
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 30,
                        ),
                        tooltip: 'Open menu',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: _BrandLogo(
                            fontSize: isSmallMobile ? 18 : 22,
                            letterSpacing: 0.8,
                            spacing: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const ApkDownloadButton(compact: true),
                    ],
                  ),
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  final double fontSize;
  final double letterSpacing;
  final double spacing;

  const _BrandLogo({
    required this.fontSize,
    this.letterSpacing = 1.2,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    // RNR1.png is a tall canvas; crop/zoom so letter height matches the text.
    final double logoHeight = fontSize * 1.1;
    final double logoWidth = fontSize * 2.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: logoHeight,
          width: logoWidth,
          child: ClipRect(
            child: Align(
              alignment: Alignment.center,
              child: Transform.scale(
                scale: 2.8,
                child: Image.asset(
                  'assets/images/RNR1.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: spacing),
        Text(
          'FITNESS GYM',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: letterSpacing,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _HeaderNavTextButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderNavTextButton({required this.label, required this.onTap});

  @override
  State<_HeaderNavTextButton> createState() => _HeaderNavTextButtonState();
}

class _HeaderNavTextButtonState extends State<_HeaderNavTextButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final Color hoverAccent = const Color(0xFFFFA812);
    final Color textColor = _isHovering ? hoverAccent : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        child: TextButton(
          onPressed: widget.onTap,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}
