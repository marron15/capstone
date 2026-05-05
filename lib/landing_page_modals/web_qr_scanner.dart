// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import 'web_js_util_stub.dart'
    if (dart.library.js_util) 'web_js_util.dart'
    as js_util;

Future<String?> showWebQrScannerDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const _WebQrScannerDialog(),
  );
}

class _WebQrScannerDialog extends StatefulWidget {
  const _WebQrScannerDialog();

  @override
  State<_WebQrScannerDialog> createState() => _WebQrScannerDialogState();
}

class _WebQrScannerDialogState extends State<_WebQrScannerDialog> {
  html.VideoElement? _videoElement;
  html.CanvasElement? _canvasElement;
  html.MediaStream? _mediaStream;
  Timer? _scanTimer;
  String? _errorMessage;
  bool _hasReturnedResult = false;
  late final String _viewType;
  bool _viewRegistered = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'web-qr-video-${DateTime.now().microsecondsSinceEpoch}';
    _initCamera();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _stopStream();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final jsQr = js_util.getProperty(html.window, 'jsQR');
    if (jsQr == null) {
      _setError('jsQR library is not available.');
      return;
    }

    try {
      final html.MediaStream? stream = await html.window.navigator.mediaDevices
          ?.getUserMedia({
            'audio': false,
            'video': {'facingMode': 'environment'},
          });

      if (stream == null) {
        _setError('Unable to access the camera.');
        return;
      }

      _mediaStream = stream;
      _videoElement =
          html.VideoElement()
            ..autoplay = true
            ..muted = true
            ..setAttribute('playsinline', 'true')
            ..srcObject = stream
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = 'cover';

      _canvasElement = html.CanvasElement();

      if (!_viewRegistered) {
        ui_web.platformViewRegistry.registerViewFactory(
          _viewType,
          (int viewId) => _videoElement!,
        );
        _viewRegistered = true;
      }

      await _videoElement!.play();
      _startScanLoop();

      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      _setError('Camera permission denied or unavailable.');
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }

  void _startScanLoop() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!mounted || _hasReturnedResult) return;
      _scanFrame();
    });
  }

  void _scanFrame() {
    final video = _videoElement;
    final canvas = _canvasElement;
    if (video == null || canvas == null) return;

    final int width = video.videoWidth;
    final int height = video.videoHeight;
    if (width == 0 || height == 0) return;

    canvas.width = width;
    canvas.height = height;

    final Object? canvasContext = js_util.callMethod(canvas, 'getContext', [
      '2d',
      js_util.jsify({'willReadFrequently': true}),
    ]);
    if (canvasContext is! html.CanvasRenderingContext2D) return;
    final ctx = canvasContext;
    ctx.drawImage(video, 0, 0);
    final imageData = ctx.getImageData(0, 0, width, height);

    final options = js_util.jsify({'inversionAttempts': 'attemptBoth'});
    final result = js_util.callMethod(html.window, 'jsQR', [
      imageData.data,
      width,
      height,
      options,
    ]);

    if (result == null) return;
    final data = js_util.getProperty(result, 'data') as String?;
    if (data == null || data.isEmpty) return;

    _hasReturnedResult = true;
    Navigator.of(context).pop(data);
  }

  void _stopStream() {
    final stream = _mediaStream;
    if (stream == null) return;
    for (final track in stream.getTracks()) {
      track.stop();
    }
    _mediaStream = null;
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isCompact = size.width < 560;

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: isCompact ? double.infinity : 420,
        height: isCompact ? 520 : 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scan Admin QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child:
                    _errorMessage != null
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        )
                        : (_videoElement == null
                            ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white70,
                                ),
                              ),
                            )
                            : HtmlElementView(viewType: _viewType)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                'Align the admin\'s QR code inside the frame. If your camera is blocked, allow access in your browser settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
