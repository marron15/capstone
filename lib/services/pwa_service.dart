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
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    // Wait a bit for JavaScript to initialize before first check
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _checkAvailability();
      }
    });
    // Set up periodic checking with longer intervals
    _startPeriodicCheck();
    // Also listen for JavaScript events
    _setupEventListeners();
  }

  void _setupEventListeners() {
    if (kIsWeb) {
      try {
        // ignore: deprecated_member_use
        js.context.callMethod('eval', [
          '''
          (function() {
            const triggerCheck = function() {
              // Trigger Flutter to check availability
              if (window.flutterPwaCheck) {
                window.flutterPwaCheck();
              }
            };
            
            window.addEventListener('pwa-installable', function() {
              window.pwaInstallable = true;
              triggerCheck();
            });
            window.addEventListener('pwa-manifest-ready', function() {
              window.pwaManifestReady = true;
              triggerCheck();
            });
            window.addEventListener('pwa-installed', function() {
              window.pwaInstalled = true;
              triggerCheck();
            });
            window.addEventListener('pwa-check-availability', function() {
              triggerCheck();
            });
            
            // Expose function for Flutter to call
            window.flutterPwaCheck = function() {
              triggerCheck();
            };
          })();
          ''',
        ]);

        // Set up a callback that Flutter can use
        // ignore: deprecated_member_use
        js.context['flutterPwaCheck'] = () {
          if (mounted) {
            _checkAvailability();
          }
        };
      } catch (e) {
        print('Error setting up PWA event listeners: $e');
      }
    }
  }

  void _startPeriodicCheck() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _checkAvailability();
        _startPeriodicCheck(); // Continue checking
      }
    });
  }

  void _checkAvailability() {
    if (!kIsWeb) {
      if (mounted) {
        setState(() {
          _isAvailable = false;
          _isChecking = false;
        });
      }
      return;
    }

    final available = PwaService.isInstallAvailable();
    if (mounted) {
      setState(() {
        _isAvailable = available;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wait a bit before showing/hiding to allow JavaScript to initialize
    if (_isChecking) {
      return const SizedBox.shrink();
    }

    // Show button when PWA install is available
    // The JavaScript function now has better fallback logic
    final showButton = _isAvailable;

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
