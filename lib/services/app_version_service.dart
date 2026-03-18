import 'package:package_info_plus/package_info_plus.dart';

class AppVersionService {
  static String? _cachedVersion;

  static Future<String> getAppVersion() async {
    if (_cachedVersion != null) {
      return _cachedVersion!;
    }

    final info = await PackageInfo.fromPlatform();
    _cachedVersion = info.version;
    return _cachedVersion!;
  }
}

