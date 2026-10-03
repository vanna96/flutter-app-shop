import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AppConfigController extends GetxController {
  static const String baseApiUrlKey = 'base_api_url';
  static const String tenantKey = 'tenant';
  static const String apiPathKey = 'api_path';

  static const String defaultBaseApiUrl = 'http://192.168.0.66:8880';
  static const String defaultTenant = 'rechna';
  static const String defaultApiPath = '/v1/api';

  final GetStorage _storage = GetStorage();

  late final RxString baseApiUrl;
  late final RxString tenant;
  late final RxString apiPath;

  @override
  void onInit() {
    super.onInit();
    final storedUrl = _storage.read<String>(baseApiUrlKey);
    final effectiveStored = (storedUrl != null && storedUrl.trim().isNotEmpty)
        ? sanitizeBaseUrl(storedUrl)
        : defaultBaseApiUrl;
    baseApiUrl = effectiveStored.obs;

    final storedTenant = _storage.read<String>(tenantKey);
    tenant = ((storedTenant != null && storedTenant.trim().isNotEmpty)
            ? storedTenant.trim()
            : defaultTenant)
        .obs;

    final storedApiPath = _storage.read<String>(apiPathKey);
    apiPath = ((storedApiPath != null && storedApiPath.trim().isNotEmpty)
            ? storedApiPath.trim()
            : defaultApiPath)
        .obs;
  }

  /// Normalizes the base API URL:
  /// - Ensures http:// or https:// scheme
  /// - Strips trailing slashes and /mobile suffix if present
  /// - Preserves the path (e.g. /v1/api, /v2/api, etc.) as entered
  static String sanitizeBaseUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.isEmpty) return '';

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }

    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.endsWith('/mobile')) {
      trimmed = trimmed.substring(0, trimmed.length - '/mobile'.length);
    }

    return trimmed;
  }

  /// Resolves the full base endpoint combining the base URL and configured API path.
  /// If the URL already contains an API path (like /v2/api or /v1/api), it uses it directly.
  static String resolveEffectiveUrl({
    required String rawUrl,
    required String tenant,
    String? apiPath,
  }) {
    final sanitized = sanitizeBaseUrl(rawUrl);
    if (sanitized.isEmpty) return defaultBaseApiUrl;

    final uri = Uri.tryParse(sanitized);
    if (uri != null && uri.path.isNotEmpty && uri.path != '/') {
      return sanitized;
    }

    final path = (apiPath != null && apiPath.trim().isNotEmpty)
        ? apiPath.trim()
        : defaultApiPath;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$sanitized$normalizedPath';
  }

  String get effectiveBaseUrl => resolveEffectiveUrl(
        rawUrl: baseApiUrl.value,
        tenant: tenant.value,
        apiPath: apiPath.value,
      );

  Future<void> updateConfig({
    required String baseApiUrlValue,
    required String tenantValue,
    String? apiPathValue,
  }) async {
    final cleanUrl = sanitizeBaseUrl(baseApiUrlValue);
    final cleanTenant = tenantValue.trim();
    final cleanApiPath = (apiPathValue != null && apiPathValue.trim().isNotEmpty)
        ? (apiPathValue.trim().startsWith('/')
            ? apiPathValue.trim()
            : '/${apiPathValue.trim()}')
        : apiPath.value;

    baseApiUrl.value = cleanUrl;
    tenant.value = cleanTenant;
    apiPath.value = cleanApiPath;

    if (cleanUrl.isEmpty) {
      await _storage.remove(baseApiUrlKey);
    } else {
      await _storage.write(baseApiUrlKey, cleanUrl);
    }

    if (cleanTenant.isEmpty) {
      await _storage.remove(tenantKey);
    } else {
      await _storage.write(tenantKey, cleanTenant);
    }

    if (cleanApiPath == defaultApiPath) {
      await _storage.remove(apiPathKey);
    } else {
      await _storage.write(apiPathKey, cleanApiPath);
    }

    await _storage.remove('tenancy_mode');
  }

  Future<void> reset() async {
    baseApiUrl.value = defaultBaseApiUrl;
    tenant.value = defaultTenant;
    apiPath.value = defaultApiPath;

    await _storage.remove(baseApiUrlKey);
    await _storage.remove(tenantKey);
    await _storage.remove(apiPathKey);
    await _storage.remove('tenancy_mode');
  }
}
