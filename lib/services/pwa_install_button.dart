import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'pwa_js_bridge.dart' as pwa_js;

class PwaInstallButton extends StatefulWidget {
  final bool compact;

  const PwaInstallButton({super.key, this.compact = false});

  @override
  State<PwaInstallButton> createState() => _PwaInstallButtonState();
}

class _PwaInstallButtonState extends State<PwaInstallButton> {
  bool _isBusy = false;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      Future<void>.delayed(const Duration(milliseconds: 500), _checkAvailability);
      _startPeriodicCheck();
    }
  }

  void _startPeriodicCheck() {
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _checkAvailability();
      _startPeriodicCheck();
    });
  }

  void _checkAvailability() {
    if (!kIsWeb) return;
    final bool available = pwa_js.isInstallAvailable();
    if (mounted && available != _isAvailable) {
      setState(() => _isAvailable = available);
    }
  }

  Future<void> _handleInstall() async {
    if (!kIsWeb) {
      _showSnackBar('App install is only available on the web version.');
      return;
    }

    if (_isBusy) return;
    setState(() => _isBusy = true);

    try {
      final bool installed = await pwa_js.triggerInstall();
      if (!mounted) return;
      _showSnackBar(
        installed
            ? 'App installed successfully!'
            : 'Installation cancelled or dismissed.',
        installed ? Colors.green : Colors.orange,
      );
      if (installed) {
        setState(() => _isAvailable = false);
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar('Install error: $error', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  void _showSnackBar(String message, [Color? background]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: background ?? Colors.black87,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !_isAvailable) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: _isBusy ? 'Installing...' : 'Install RNR Fitness App',
      child:
          widget.compact
              ? IconButton(
                onPressed: _isBusy ? null : _handleInstall,
                tooltip: _isBusy ? 'Installing...' : 'Install App',
                icon:
                    _isBusy
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(
                          Icons.install_mobile,
                          color: Colors.white,
                          size: 24,
                        ),
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                  padding: const EdgeInsets.all(8),
                ),
              )
              : TextButton.icon(
                onPressed: _isBusy ? null : _handleInstall,
                icon:
                    _isBusy
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(
                          Icons.install_mobile,
                          color: Colors.white,
                          size: 18,
                        ),
                label: const Text(
                  'Install',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
    );
  }
}
