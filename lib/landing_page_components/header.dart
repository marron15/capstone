import 'package:flutter/material.dart';
import '../services/unified_auth_state.dart';
import '../services/apk_download_button.dart';
import 'sidenav.dart';

// TRANSPARENT HEADER (moved from main.dart)
class MainHeader extends StatelessWidget {
  final bool isScrolled;
  final void Function(String section)? onSectionTap;
  const MainHeader({super.key, this.isScrolled = false, this.onSectionTap});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double topInset = MediaQuery.of(context).padding.top;
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;
    final bool isSmallMobile = screenSize.width < 420;
    final double expandedHeaderHeight =
        isDesktop ? 160 : (isSmallMobile ? 96 : 108);
    final double collapsedHeaderHeight =
        isDesktop ? 80 : (isSmallMobile ? 68 : 74);
    final double horizontalPadding =
        isDesktop
            ? 40
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
          child: Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isDesktop)
                  IconButton(
                    onPressed: openMobileMenu,
                    icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                    tooltip: 'Open menu',
                  ),
                if (!isDesktop) const SizedBox(width: 8),
                if (isDesktop)
                  const Text(
                    'RNR FITNESS GYM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      'RNR FITNESS GYM',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallMobile ? 22 : 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                if (isDesktop) const Spacer(),
                if (!isDesktop) const SizedBox(width: 6),
                if (isDesktop) ...[
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
                    onTap: () => onSectionTap?.call('Inquiries'),
                  ),
                  _HeaderNavTextButton(
                    label: 'About Us',
                    onTap: () => onSectionTap?.call('About Us'),
                  ),
                  const Spacer(),
                ],
                if (isDesktop) ...[
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
                                size: 40,
                              ),
                              tooltip: 'Profile',
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: handleLogout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withValues(
                                  alpha: 0.8,
                                ),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
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
                if (!isDesktop) const ApkDownloadButton(compact: true),
              ],
            ),
          ),
        ),
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}
