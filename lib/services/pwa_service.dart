import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: deprecated_member_use
import 'dart:js' as js;

/// Service for PWA install functionality
///
/// Note: Uses dart:js for JavaScript interop which is deprecated but
/// functional and stable for production use.
class PwaService {
  /// Check if PWA install is available
  static bool isInstallAvailable() {
    try {
      if (kIsWeb) {
        try {
          // ignore: deprecated_member_use
          final result = js.context.callMethod('isPwaInstallAvailable', []);
          return result == true;
        } catch (e) {
          return false;
        }
      }
      return false;
    } catch (e) {
      print('Error checking PWA install availability: $e');
      return false;
    }
  }

  /// Trigger PWA install prompt
  static Future<bool> triggerInstall() async {
    try {
      if (kIsWeb) {
        try {
          // ignore: deprecated_member_use
          final result = js.context.callMethod('triggerPwaInstall', []);
          return result == true || result == 'accepted';
        } catch (e) {
          return false;
        }
      }
      return false;
    } catch (e) {
      print('Error triggering PWA install: $e');
      return false;
    }
  }

  /// Show install button based on availability
  static Widget buildInstallButton(BuildContext context) {
    return _PwaInstallButtonWidget();
  }
}

class _PwaInstallButtonWidget extends StatefulWidget {
  @override
  State<_PwaInstallButtonWidget> createState() =>
      _PwaInstallButtonWidgetState();
}

class _PwaInstallButtonWidgetState extends State<_PwaInstallButtonWidget> {
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
    // Set up periodic checking
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkAvailability();
        _startPeriodicCheck(); // Continue checking
      }
    });
  }

  void _checkAvailability() {
    final available = PwaService.isInstallAvailable();
    if (mounted && available != _isAvailable) {
      setState(() {
        _isAvailable = available;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show button even in development for testing purposes
    // In production, this will only show when PWA install is available
    final showButton = _isAvailable || kDebugMode;

    if (!showButton) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.download, color: Colors.white),
      tooltip: _isAvailable ? 'Install App' : 'Install App (Dev Mode)',
      onPressed: () async {
        try {
          final installed = await PwaService.triggerInstall();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  installed
                      ? 'App installed successfully!'
                      : 'Installation cancelled or dismissed.',
                ),
                backgroundColor: installed ? Colors.green : Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          // Update availability after install attempt
          if (mounted) {
            setState(() {
              _isAvailable = false;
            });
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Install error: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
    );
  }
}
