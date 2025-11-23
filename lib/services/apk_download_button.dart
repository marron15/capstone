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
      message: _isBusy ? 'Preparing APK...' : 'Download Rnr Gym APK',
      child: IconButton(
        iconSize: 40,
        padding: EdgeInsets.zero,
        onPressed: _isBusy ? null : _handleDownload,
        icon: Stack(
          alignment: Alignment.center,
          children: [
            _ApkIcon(),
            if (_isBusy)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color.fromARGB(150, 0, 0, 0),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ApkIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/icons/app_icon.png',
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.android, color: Colors.white, size: 28);
        },
      ),
    );
  }
}
