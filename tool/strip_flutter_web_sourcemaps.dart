// Strips trailing //# sourceMappingURL=... comments from root-level *.js files.
//
// Flutter release output references flutter.js.map but does not ship it (404).
// Vendored jsQR (jsqr.min.js) references /sm/*.map which is also absent on static
// hosts — Safari reports "Source Map loading errors" in the console.
//
// Usage (after `flutter build web`):
//   dart run tool/strip_flutter_web_sourcemaps.dart
//
// By default processes `build/web` and `web` when those directories exist.
// Pass explicit directories: dart run tool/strip_flutter_web_sourcemaps.dart build/web

import 'dart:io';

void main(List<String> args) {
  final List<String> dirs =
      args.isNotEmpty ? args : <String>['build/web', 'web'];

  final RegExp strip = RegExp(
    r'[\r\n]*//#\s*sourceMappingURL=[^\r\n]+\s*',
    multiLine: true,
  );

  for (final String webDir in dirs) {
    final Directory d = Directory(webDir);
    if (!d.existsSync()) {
      stderr.writeln('strip_web_sourcemaps: skip (missing dir): $webDir');
      continue;
    }
    for (final FileSystemEntity e in d.listSync()) {
      if (e is! File) continue;
      if (!e.path.endsWith('.js')) continue;
      final String before = e.readAsStringSync();
      final String after = before.replaceAll(strip, '');
      if (after != before) {
        e.writeAsStringSync(after);
        stdout.writeln('strip_web_sourcemaps: updated ${e.path}');
      }
    }
  }
}
