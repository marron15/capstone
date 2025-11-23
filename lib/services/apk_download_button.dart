import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'apk_download_service.dart';

class ApkDownloadButton extends StatefulWidget {
  const ApkDownloadButton({super.key});

  @override
  State<ApkDownloadButton> createState() => _ApkDownloadButtonState();
}

class _ApkDownloadButtonState extends State<ApkDownloadButton> {
  bool _isBusy = false;

  Future<void> _handleDownload() async {
    if (!kIsWeb) {
      _showSnackBar('APK download is only available on the web version.');
      return;
    }

    if (_isBusy) return;
    setState(() {
      _isBusy = true;
    });

    final bool started = await ApkDownloadService.triggerDownload();
    if (!mounted) return;
    _showSnackBar(
      started
          ? 'Starting download for ${ApkDownloadService.apkFileName}'
          : 'APK file is missing. Please upload it to web/downloads.',
      started ? Colors.green : Colors.orange,
    );

    if (mounted) {
      setState(() {
        _isBusy = false;
      });
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
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: _isBusy ? 'Preparing APK...' : 'Install Rnr Gym App',
      child: TextButton.icon(
        onPressed: _isBusy ? null : _handleDownload,
        icon:
            _isBusy
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Icon(Icons.download, color: Colors.white, size: 18),
        label: const Text(
          'Install App',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
