import 'package:web/web.dart' as web;

Future<bool> startApkDownload(Uri uri, String fileName) async {
  final anchor =
      web.HTMLAnchorElement()
        ..download = fileName
        ..target = '_blank'
        ..href = uri.toString()
        ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  return true;
}
