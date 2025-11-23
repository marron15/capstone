import 'package:flutter/foundation.dart';

import 'apk_download_portal.dart' as portal;

class ApkDownloadService {
  static const String apkFileName = 'Rnr Gym.apk';
  static const String apkRelativePath = 'downloads/rnr_gym.apk';

  static Future<bool> triggerDownload() async {
    if (!kIsWeb) {
      return false;
    }

    final Uri baseUri = Uri.base;
    final Uri downloadUri = baseUri.resolve(apkRelativePath);
    return portal.startApkDownload(downloadUri, apkFileName);
  }
}

