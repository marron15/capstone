import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'pwa_event_listener.dart' as pwa_events;
import 'pwa_js_bridge.dart' as pwa_js;

class PwaInstallButton extends StatefulWidget {
  final bool compact;

  const PwaInstallButton({super.key, this.compact = false});

  @override
  State<PwaInstallButton> createState() => _PwaInstallButtonState();
}

class _PwaInstallButtonState extends State<PwaInstallButton> {
  static const Color _accent = Color(0xFFFF8C00);
  static const Color _accentLight = Color(0xFFFFA812);

  bool _isBusy = false;
  bool _isStandalone = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _refreshState();
      pwa_events.listenForPwaEvents(_refreshState);
      Future<void>.delayed(const Duration(milliseconds: 300), _refreshState);
      Future<void>.delayed(const Duration(seconds: 2), _refreshState);
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      pwa_events.removePwaEventListeners(_refreshState);
    }
    super.dispose();
  }

  void _refreshState() {
    if (!kIsWeb || !mounted) return;
    try {
      final bool standalone = pwa_js.isStandalone();
      if (standalone != _isStandalone) {
        setState(() => _isStandalone = standalone);
      }
    } catch (_) {
      // JS bridge not ready yet; keep the install button visible.
    }
  }

  Future<void> _showAlreadyInstalledAlert() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Already installed'),
          content: const Text(
            'You have already added RNR Fitness Gym as an app on this device. '
            'Open it from your home screen or app launcher.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _handleInstall() {
    if (!kIsWeb) {
      _showSnackBar('App install is only available on the web version.');
      return;
    }

    if (_isBusy) return;

    final bool installed = pwa_js.isInstalled();
    final String reason = pwa_js.installReason();
    if (installed ||
        reason == 'installed' ||
        reason == 'already-installed-or-used') {
      _showAlreadyInstalledAlert();
      return;
    }

    // prompt() must run synchronously inside the click handler (before await/setState).
    final bool prompted = pwa_js.triggerInstallPromptSync();
    if (!prompted) {
      _showSnackBar(_messageForReason(pwa_js.installReason()), Colors.orange);
      return;
    }

    setState(() => _isBusy = true);

    pwa_js.getInstallOutcome().then((String outcome) {
      if (!mounted) return;
      if (outcome == 'accepted') {
        _showSnackBar('App installed successfully!', Colors.green);
        setState(() {
          _isStandalone = true;
          _isBusy = false;
        });
        return;
      }

      _showSnackBar(
        outcome == 'dismissed'
            ? 'Installation cancelled.'
            : 'Installation could not be completed.',
        Colors.orange,
      );
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }).catchError((Object error) {
      if (!mounted) return;
      _showSnackBar('Install error: $error', Colors.red);
      setState(() => _isBusy = false);
    });
  }

  String _messageForReason(String reason) {
    switch (reason) {
      case 'ios':
        return 'To install: tap the Share button, then "Add to Home Screen".';
      case 'insecure':
        return 'Install needs a secure (https) connection.';
      case 'no-manifest':
        return 'App manifest not found on the server. Please contact the gym.';
      case 'no-sw':
        return 'Setting up offline support. Please wait a moment and try again.';
      case 'unsupported-browser':
        return 'This browser cannot install the app. Try Chrome, Edge, or Safari.';
      case 'installed':
        return 'The app is already installed. Open it from your home screen.';
      case 'already-installed-or-used':
        return 'The app may already be installed. Look for the install icon in '
            'the address bar, or open it from your apps/home screen.';
      default:
        return 'Install is not available right now. Try the install icon in the '
            'address bar, or your browser menu → "Install app".';
    }
  }

  void _showSnackBar(String message, [Color? background]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: background ?? Colors.black87,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _isStandalone) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: _isBusy ? 'Installing...' : 'Install RNR Fitness App',
      child:
          widget.compact ? _buildCompactButton() : _buildDesktopButton(),
    );
  }

  Widget _buildCompactButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isBusy ? null : _handleInstall,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[_accentLight, _accent],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _accent.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: _buildLeadingIcon(size: 16)),
        ),
      ),
    );
  }

  Widget _buildDesktopButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isBusy ? null : _handleInstall,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[_accentLight, _accent],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _accent.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildLeadingIcon(size: 15),
              const SizedBox(width: 6),
              const Text(
                'Install App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon({required double size}) {
    if (_isBusy) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Container(
      width: size + 6,
      height: size + 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(5),
      ),
      // Vector-painted download icon so it never depends on the Material
      // Icons font subset (which can be stale-cached after a deploy).
      child: Center(
        child: CustomPaint(
          size: Size(size, size),
          painter: _DownloadIconPainter(color: Colors.white),
        ),
      ),
    );
  }
}

/// Draws a classic "download / install" glyph (down arrow into a tray) using
/// pure vectors so it renders regardless of icon-font caching or tree-shaking.
class _DownloadIconPainter extends CustomPainter {
  const _DownloadIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = (w * 0.12).clamp(1.4, 2.6)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    // Arrow shaft.
    canvas.drawLine(Offset(w * 0.5, h * 0.08), Offset(w * 0.5, h * 0.6), paint);

    // Arrow head (downward chevron).
    final Path head =
        Path()
          ..moveTo(w * 0.28, h * 0.4)
          ..lineTo(w * 0.5, h * 0.64)
          ..lineTo(w * 0.72, h * 0.4);
    canvas.drawPath(head, paint);

    // Tray / base line.
    canvas.drawLine(Offset(w * 0.22, h * 0.9), Offset(w * 0.78, h * 0.9), paint);
  }

  @override
  bool shouldRepaint(_DownloadIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
