import 'dart:io';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/version_update_dialog.dart';

class VersionControlService {
  /// Get current app version from package_info_plus
  static Future<String> getCurrentVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (_) {
      return '1.0.0';
    }
  }

  /// Compares local version with backend minimum version.
  /// If local version is strictly less than minimum required version,
  /// returns true (force update required).
  static Future<bool> isForceUpdateRequired(String minimumVersion) async {
    if (minimumVersion.isEmpty) return false;

    try {
      final String currentVersion = await getCurrentVersion();
      return _isVersionLower(currentVersion, minimumVersion);
    } catch (_) {
      return false; // Silently fail and don't force update if we can't parse
    }
  }

  /// Compares local version with backend latest version.
  /// If local version is strictly less than latest version,
  /// returns true (optional update available).
  static Future<bool> isOptionalUpdateAvailable(String latestVersion) async {
    if (latestVersion.isEmpty) return false;

    try {
      final String currentVersion = await getCurrentVersion();
      return _isVersionLower(currentVersion, latestVersion);
    } catch (_) {
      return false;
    }
  }

  /// Launch the respective store URL
  static Future<void> launchStore(String iosUrl, String androidUrl) async {
    String targetUrl = Platform.isIOS ? iosUrl : androidUrl;
    if (targetUrl.isEmpty) return;

    final Uri url = Uri.parse(targetUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Compares two semantic versions. Returns true if v1 < v2.
  static bool _isVersionLower(String v1, String v2) {
    final v1Parts = v1.split('.');
    final v2Parts = v2.split('.');

    for (int i = 0; i < 3; i++) {
      final int p1 = i < v1Parts.length ? int.tryParse(v1Parts[i]) ?? 0 : 0;
      final int p2 = i < v2Parts.length ? int.tryParse(v2Parts[i]) ?? 0 : 0;

      if (p1 < p2) return true;
      if (p1 > p2) return false;
    }
    return false; // versions are equal
  }

  /// Show a non-dismissible dialog for force update
  static void showForceUpdateDialog(
    String iosUrl,
    String androidUrl, {
    String? minVersion,
    String? latestVersion,
  }) async {
    final String current = await getCurrentVersion();
    Get.dialog(
      VersionUpdateDialog(
        isForceUpdate: true,
        currentVersion: current,
        newVersion: (latestVersion != null && latestVersion.isNotEmpty)
            ? latestVersion
            : minVersion,
        iosUrl: iosUrl,
        androidUrl: androidUrl,
      ),
      barrierDismissible: false,
    );
  }

  /// Show an optional/dismissible update dialog
  static void showOptionalUpdateDialog(
    String iosUrl,
    String androidUrl, {
    String? latestVersion,
  }) async {
    final String current = await getCurrentVersion();
    Get.dialog(
      VersionUpdateDialog(
        isForceUpdate: false,
        currentVersion: current,
        newVersion: latestVersion,
        iosUrl: iosUrl,
        androidUrl: androidUrl,
      ),
      barrierDismissible: true,
    );
  }
}
