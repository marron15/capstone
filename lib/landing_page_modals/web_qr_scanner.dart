// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/material.dart';

import 'web_js_util_stub.dart'
    if (dart.library.js_util) 'web_js_util.dart'
    as js_util;

/// Web-only QR scanner. Uses a native DOM full-screen overlay for the camera
/// preview so Safari (especially with CanvasKit) does not show a black
/// [HtmlElementView] compositing bug. Load `jsqr.min.js` from the same origin as
/// the app so Safari privacy / tracker blocking does not remove a CDN script.
Future<String?> showWebQrScannerDialog(BuildContext context) {
  final Completer<String?> completer = Completer<String?>();
  _DomQrScannerOverlay.show(completer);
  return completer.future;
}

class _DomQrScannerOverlay {
  _DomQrScannerOverlay._(this._completer);

  final Completer<String?> _completer;
  html.DivElement? _backdrop;
  final List<StreamSubscription<dynamic>> _subs =
      <StreamSubscription<dynamic>>[];
  StreamSubscription<html.Event>? _keySub;
  bool _finished = false;

  html.VideoElement? _video;
  html.CanvasElement? _canvas;
  html.MediaStream? _mediaStream;
  Timer? _scanTimer;

  static void show(Completer<String?> completer) {
    _DomQrScannerOverlay._(completer)._install();
  }

  /// Blocking message (e.g. jsQR missing); completes with null when user dismisses.
  static void _showBlockingError(Completer<String?> completer, String message) {
    final html.DivElement backdrop =
        html.DivElement()
          ..style.setProperty('position', 'fixed')
          ..style.setProperty('inset', '0')
          ..style.setProperty('z-index', '2147483000')
          ..style.setProperty('background', 'rgba(0,0,0,0.82)')
          ..style.setProperty('display', 'flex')
          ..style.setProperty('align-items', 'center')
          ..style.setProperty('justify-content', 'center')
          ..style.setProperty('padding', '24px')
          ..style.setProperty('box-sizing', 'border-box');

    final html.DivElement panel =
        html.DivElement()
          ..style.setProperty('max-width', '420px')
          ..style.setProperty('background', '#1a1a1a')
          ..style.setProperty('border-radius', '12px')
          ..style.setProperty('padding', '20px 22px')
          ..style.setProperty('color', '#e0e0e0')
          ..style.setProperty(
            'font',
            '14px/1.45 system-ui, -apple-system, sans-serif',
          );

    final html.ParagraphElement p =
        html.ParagraphElement()
          ..text = message
          ..style.margin = '0 0 16px 0';

    final html.ButtonElement btn =
        html.ButtonElement()
          ..text = 'Close'
          ..type = 'button'
          ..style.setProperty('padding', '10px 18px')
          ..style.setProperty('border-radius', '8px')
          ..style.setProperty('border', 'none')
          ..style.setProperty('cursor', 'pointer')
          ..style.setProperty('font-weight', '600')
          ..style.setProperty('background', '#ffffff')
          ..style.setProperty('color', '#000000');

    panel.children.addAll(<html.Element>[p, btn]);
    backdrop.append(panel);

    final List<StreamSubscription<dynamic>> subs =
        <StreamSubscription<dynamic>>[];

    void dismiss() {
      for (final StreamSubscription<dynamic> s in subs) {
        s.cancel();
      }
      subs.clear();
      backdrop.remove();
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }

    subs.add(
      backdrop.onClick.listen((html.MouseEvent e) {
        if (e.target == backdrop) {
          dismiss();
        }
      }),
    );
    subs.add(
      panel.onClick.listen((html.MouseEvent e) {
        e.stopPropagation();
      }),
    );
    subs.add(btn.onClick.listen((_) => dismiss()));
    subs.add(
      html.document.onKeyDown.listen((html.KeyboardEvent e) {
        if (e.key == 'Escape') {
          e.preventDefault();
          dismiss();
        }
      }),
    );

    html.document.body?.append(backdrop);
  }

  void _install() {
    final Object? jsQr = js_util.getProperty(html.window, 'jsQR');
    if (jsQr == null) {
      _DomQrScannerOverlay._showBlockingError(
        _completer,
        'QR scanner could not load (jsQR missing). '
        'Ensure jsqr.min.js is deployed next to index.html, then hard-refresh.',
      );
      return;
    }

    if (!_isSecureEnoughForCamera()) {
      _DomQrScannerOverlay._showBlockingError(
        _completer,
        'Camera needs HTTPS (or localhost). Open the site with https://.',
      );
      return;
    }

    final html.DivElement backdrop =
        html.DivElement()
          ..id = 'rnr-web-qr-scanner-backdrop'
          ..style.setProperty('position', 'fixed')
          ..style.setProperty('inset', '0')
          ..style.setProperty('z-index', '2147483000')
          ..style.setProperty('background', 'rgba(0,0,0,0.72)')
          ..style.setProperty('display', 'flex')
          ..style.setProperty('align-items', 'center')
          ..style.setProperty('justify-content', 'center')
          ..style.setProperty('padding', '16px')
          ..style.setProperty('box-sizing', 'border-box');

    final html.DivElement panel =
        html.DivElement()
          ..style.setProperty('width', '100%')
          ..style.setProperty('max-width', '420px')
          ..style.setProperty('max-height', 'min(560px, 92vh)')
          ..style.setProperty('background', '#000000')
          ..style.setProperty('border-radius', '12px')
          ..style.setProperty('overflow', 'hidden')
          ..style.setProperty('display', 'flex')
          ..style.setProperty('flex-direction', 'column')
          ..style.setProperty('box-shadow', '0 12px 40px rgba(0,0,0,0.45)');

    final html.DivElement header =
        html.DivElement()
          ..style.setProperty('display', 'flex')
          ..style.setProperty('align-items', 'center')
          ..style.setProperty('justify-content', 'space-between')
          ..style.setProperty('padding', '12px 16px')
          ..style.setProperty('flex-shrink', '0');

    final html.SpanElement title =
        html.SpanElement()
          ..text = 'Scan Admin QR'
          ..style.setProperty('color', '#ffffff')
          ..style.setProperty(
            'font',
            '600 16px system-ui, -apple-system, sans-serif',
          );

    final html.ButtonElement closeBtn =
        html.ButtonElement()
          ..text = '✕'
          ..type = 'button'
          ..style.setProperty('border', 'none')
          ..style.setProperty('background', 'transparent')
          ..style.setProperty('color', '#ffffff')
          ..style.setProperty('font-size', '20px')
          ..style.setProperty('line-height', '1')
          ..style.setProperty('cursor', 'pointer')
          ..style.setProperty('padding', '4px 8px');

    header.children.addAll(<html.Element>[title, closeBtn]);

    final html.DivElement videoHost =
        html.DivElement()
          ..style.setProperty('flex', '1')
          ..style.setProperty('min-height', '280px')
          ..style.setProperty('width', '100%')
          ..style.setProperty('align-self', 'stretch')
          ..style.setProperty('background', '#000000')
          ..style.setProperty('position', 'relative')
          ..style.setProperty('display', 'flex')
          ..style.setProperty('align-items', 'center')
          ..style.setProperty('justify-content', 'center');

    final html.DivElement status =
        html.DivElement()
          ..style.setProperty('color', '#bfbfbf')
          ..style.setProperty(
            'font',
            '13px/1.4 system-ui, -apple-system, sans-serif',
          )
          ..style.setProperty('text-align', 'center')
          ..style.setProperty('padding', '0 20px')
          ..text = 'Starting camera…';

    videoHost.append(status);

    final html.DivElement footer =
        html.DivElement()
          ..style.setProperty('padding', '14px 16px')
          ..style.setProperty('flex-shrink', '0')
          ..style.setProperty('color', '#bfbfbf')
          ..style.setProperty(
            'font',
            '12px/1.45 system-ui, -apple-system, sans-serif',
          )
          ..style.setProperty('text-align', 'center')
          ..text =
              'Align the admin QR in frame. Use https://. Safari Private can block '
              'camera — try a normal window. Allow camera for this site in settings.';

    panel.children.addAll(<html.Element>[header, videoHost, footer]);
    backdrop.append(panel);

    _subs.add(
      backdrop.onClick.listen((html.MouseEvent e) {
        if (e.target == backdrop) {
          _close(null);
        }
      }),
    );
    _subs.add(
      panel.onClick.listen((html.MouseEvent e) {
        e.stopPropagation();
      }),
    );
    _subs.add(
      closeBtn.onClick.listen((_) {
        _close(null);
      }),
    );

    _keySub = html.document.onKeyDown.listen((html.KeyboardEvent e) {
      if (e.key == 'Escape') {
        e.preventDefault();
        _close(null);
      }
    });

    html.document.body?.append(backdrop);
    _backdrop = backdrop;

    _startCamera(videoHost, status);
  }

  /// Browsers only expose the camera on HTTPS (or localhost).
  static bool _isSecureEnoughForCamera() {
    final String protocol = html.window.location.protocol;
    if (protocol == 'https:') return true;
    final String? host = html.window.location.hostname;
    return host == 'localhost' || host == '127.0.0.1' || host == '[::1]';
  }

  static Future<html.MediaStream?> _requestCameraStream() async {
    final html.MediaDevices? devices = html.window.navigator.mediaDevices;
    if (devices == null) return null;

    Future<html.MediaStream?> tryConstraints(
      Map<String, Object?> constraints,
    ) async {
      try {
        return await devices.getUserMedia(constraints);
      } catch (_) {
        return null;
      }
    }

    return await tryConstraints({
          'audio': false,
          'video': <String, Object?>{
            'facingMode': <String, String>{'ideal': 'environment'},
          },
        }) ??
        await tryConstraints({
          'audio': false,
          'video': <String, Object?>{'facingMode': 'environment'},
        }) ??
        await tryConstraints({
          'audio': false,
          'video': <String, Object?>{
            'facingMode': <String, String>{'ideal': 'user'},
          },
        }) ??
        await tryConstraints({
          'audio': false,
          'video': <String, Object?>{'facingMode': 'user'},
        }) ??
        await tryConstraints({'audio': false, 'video': true});
  }

  Future<void> _startCamera(
    html.DivElement videoHost,
    html.DivElement status,
  ) async {
    try {
      final html.MediaStream? stream = await _requestCameraStream();
      if (stream == null) {
        status.text =
            'Could not open the camera. Allow camera for this site, or try outside '
            'Safari Private Browsing.';
        return;
      }

      _mediaStream = stream;
      final html.VideoElement video =
          html.VideoElement()
            ..autoplay = true
            ..muted = true
            ..setAttribute('playsinline', 'true')
            ..setAttribute('webkit-playsinline', 'true')
            ..srcObject = stream
            ..style.setProperty('width', '100%')
            ..style.setProperty('height', '100%')
            ..style.setProperty('object-fit', 'cover')
            ..style.setProperty('display', 'block');

      status.remove();
      videoHost.append(video);
      _video = video;

      _canvas = html.CanvasElement()..style.setProperty('display', 'none');

      try {
        await video.play();
      } catch (_) {
        try {
          await video.onLoadedMetadata.first;
          await video.play();
        } catch (_) {}
      }

      _scanTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
        if (_finished) return;
        _scanFrame();
      });
    } catch (_) {
      status.text =
          'Camera permission denied or blocked. Safari → Settings → Websites → '
          'Camera for this site. Private Browsing may disable camera.';
    }
  }

  void _scanFrame() {
    final html.VideoElement? video = _video;
    final html.CanvasElement? canvas = _canvas;
    if (video == null || canvas == null || _finished) return;

    final int width = video.videoWidth;
    final int height = video.videoHeight;
    if (width == 0 || height == 0) return;

    canvas.width = width;
    canvas.height = height;

    Object? canvasContext;
    try {
      canvasContext = js_util.callMethod(canvas, 'getContext', [
        '2d',
        js_util.jsify(<String, bool>{'willReadFrequently': true}),
      ]);
    } catch (_) {
      canvasContext = null;
    }
    if (canvasContext is! html.CanvasRenderingContext2D) {
      canvasContext = js_util.callMethod(canvas, 'getContext', ['2d']);
    }
    if (canvasContext is! html.CanvasRenderingContext2D) return;
    final html.CanvasRenderingContext2D ctx = canvasContext;
    ctx.drawImage(video, 0, 0);
    final html.ImageData imageData = ctx.getImageData(0, 0, width, height);

    final Object options = js_util.jsify(<String, String>{
      'inversionAttempts': 'attemptBoth',
    });
    final Object? result = js_util.callMethod(html.window, 'jsQR', [
      imageData.data,
      width,
      height,
      options,
    ]);

    if (result == null) return;
    final String? data = js_util.getProperty(result, 'data') as String?;
    if (data == null || data.isEmpty) return;

    _close(data);
  }

  void _close(String? payload) {
    if (_finished) return;
    _finished = true;
    _scanTimer?.cancel();
    _scanTimer = null;
    for (final StreamSubscription<dynamic> s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _keySub?.cancel();
    _keySub = null;
    final html.MediaStream? stream = _mediaStream;
    if (stream != null) {
      for (final html.MediaStreamTrack t in stream.getTracks()) {
        t.stop();
      }
    }
    _mediaStream = null;
    _video = null;
    _canvas = null;
    _backdrop?.remove();
    _backdrop = null;

    if (!_completer.isCompleted) {
      _completer.complete(payload);
    }
  }
}
