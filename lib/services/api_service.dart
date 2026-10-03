import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grocery_app/controllers/app_config_controller.dart';
import 'package:grocery_app/controllers/network_status_controller.dart';
import 'package:get/get.dart' hide Response;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final GetStorage _storage = GetStorage();
  late Dio dio;

  ApiService._internal() {
    _configureDio();
  }

  void refreshConfig() {
    _configureDio();
  }

  void _configureDio() {
    final storedUrl =
        _storage.read<String>(AppConfigController.baseApiUrlKey);
    final rawBaseApiUrl = (storedUrl != null && storedUrl.trim().isNotEmpty)
        ? AppConfigController.sanitizeBaseUrl(storedUrl.trim())
        : AppConfigController.defaultBaseApiUrl;

    final storedTenant =
        _storage.read<String>(AppConfigController.tenantKey);
    final tenant = (storedTenant != null && storedTenant.trim().isNotEmpty)
        ? storedTenant.trim()
        : AppConfigController.defaultTenant;

    final storedApiPath =
        _storage.read<String>(AppConfigController.apiPathKey);
    final apiPath = (storedApiPath != null && storedApiPath.trim().isNotEmpty)
        ? storedApiPath.trim()
        : AppConfigController.defaultApiPath;

    final baseApiUrl = _normalizeBaseUrl(rawBaseApiUrl, apiPath: apiPath);
    final user = _storage.read('user');
    final token = user is Map ? user['token']?.toString() ?? '' : '';

    dio = Dio(
      BaseOptions(
        baseUrl: baseApiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          "x-api-key": "Testing",
          if (tenant.isNotEmpty) "x-tenant": tenant,
          if (token.isNotEmpty) "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          if (Get.isRegistered<NetworkStatusController>()) {
            Get.find<NetworkStatusController>().markAvailable();
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (Get.isRegistered<NetworkStatusController>()) {
            final controller = Get.find<NetworkStatusController>();
            final statusCode = error.response?.statusCode;

            if (error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.sendTimeout ||
                error.type == DioExceptionType.receiveTimeout) {
              controller.markUnavailable(
                'The server is taking too long to respond',
              );
            } else if (error.type == DioExceptionType.connectionError ||
                error.type == DioExceptionType.unknown) {
              controller.markUnavailable(
                'No internet connection or the server is unavailable',
              );
            } else if (statusCode != null && statusCode >= 500) {
              controller.markUnavailable(
                'The server is temporarily unavailable',
              );
            } else if (error.response != null) {
              // A non-5xx HTTP response confirms that the server is reachable.
              controller.markAvailable();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  String _normalizeBaseUrl(String effectiveUrl, {String? apiPath}) =>
      _staticNormalizeBaseUrl(effectiveUrl, apiPath: apiPath);

  static String normalizeBaseUrl(String effectiveUrl, {String? apiPath}) =>
      _staticNormalizeBaseUrl(effectiveUrl, apiPath: apiPath);

  static String _staticNormalizeBaseUrl(String effectiveUrl, {String? apiPath}) {
    var trimmed = effectiveUrl.trim();
    if (trimmed.isEmpty) {
      trimmed = AppConfigController.defaultBaseApiUrl;
    }
    if (trimmed.isEmpty) {
      return '';
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    final normalized = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;

    if (normalized.endsWith('/mobile')) {
      return normalized.substring(0, normalized.length - '/mobile'.length);
    }

    // If the URL already contains a path like /v1/api or /v2/api, use it as is
    final uri = Uri.tryParse(normalized);
    if (uri != null && uri.path.isNotEmpty && uri.path != '/') {
      return normalized;
    }

    // Otherwise, append the configured apiPath
    final path = (apiPath != null && apiPath.trim().isNotEmpty)
        ? apiPath.trim()
        : AppConfigController.defaultApiPath;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$normalized$normalizedPath';
  }

  /// Pings the remote API with Base API URL and tenant to verify connectivity.
  static Future<ConnectionTestResult> testConnection({
    required String rawUrl,
    required String tenant,
    String? apiPath,
  }) async {
    final cleanInputUrl = AppConfigController.sanitizeBaseUrl(rawUrl);
    final cleanTenant = tenant.trim();
    final normalized = _staticNormalizeBaseUrl(cleanInputUrl, apiPath: apiPath);

    final stopwatch = Stopwatch()..start();
    try {
      final dioClient = Dio(
        BaseOptions(
          baseUrl: normalized,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: {
            "x-api-key": "Testing",
            if (cleanTenant.isNotEmpty) "x-tenant": cleanTenant,
            "Accept": "application/json",
          },
        ),
      );

      final response = await dioClient.get('/mobile/branches');
      stopwatch.stop();

      int branchCount = 0;
      if (response.data is Map && response.data['data'] is List) {
        branchCount = (response.data['data'] as List).length;
      }

      return ConnectionTestResult(
        isSuccess: true,
        statusCode: response.statusCode ?? 200,
        latencyMs: stopwatch.elapsedMilliseconds,
        message: 'Connected successfully!',
        testedUrl: '$normalized/mobile/branches',
        tenantDetected: cleanTenant.isNotEmpty ? cleanTenant : 'None',
        branchCount: branchCount,
        details:
            'Server returned HTTP ${response.statusCode} with $branchCount branch(es).',
      );
    } on DioException catch (dioErr) {
      stopwatch.stop();
      return _buildErrorResult(
        dioErr: dioErr,
        latencyMs: stopwatch.elapsedMilliseconds,
        testedUrl: '$normalized/mobile/branches',
        tenant: cleanTenant,
      );
    } catch (e) {
      stopwatch.stop();
      return ConnectionTestResult(
        isSuccess: false,
        statusCode: 0,
        latencyMs: stopwatch.elapsedMilliseconds,
        message: 'Connection error',
        testedUrl: '$normalized/mobile/branches',
        details: e.toString(),
      );
    }
  }

  static ConnectionTestResult _buildErrorResult({
    required DioException dioErr,
    required int latencyMs,
    required String testedUrl,
    required String tenant,
  }) {
    String message = 'Connection failed';
    String details = dioErr.message ?? 'Unknown network error';
    final code = dioErr.response?.statusCode ?? 0;

    if (dioErr.type == DioExceptionType.connectionTimeout ||
        dioErr.type == DioExceptionType.sendTimeout ||
        dioErr.type == DioExceptionType.receiveTimeout) {
      message = 'Request timed out (6s)';
      details =
          'Server did not respond in time. Verify host IP, port, and firewall.';
    } else if (dioErr.type == DioExceptionType.connectionError) {
      message = 'Host unreachable';
      details =
          'Could not establish connection to $testedUrl. Ensure Docker/Nginx is running on this port and reachable from your device.';
    } else if (code == 404) {
      message = 'Endpoint or Tenant not found (404)';
      details = tenant.isNotEmpty
          ? 'Tenant "$tenant" may not exist in database or route is wrong.'
          : 'Endpoint route not found on this domain.';
    } else if (code == 401 || code == 403) {
      message = 'Access Denied ($code)';
      details =
          'Server rejected the request. Check x-api-key or tenant permissions.';
    } else if (code >= 500) {
      message = 'Server Error ($code)';
      details =
          'Backend returned internal error. Check docker logs or php debug bar.';
    }

    return ConnectionTestResult(
      isSuccess: false,
      statusCode: code,
      latencyMs: latencyMs,
      message: message,
      testedUrl: testedUrl,
      details: details,
    );
  }

  Future<Response<dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return dio.get(endpoint, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return dio.post(endpoint, data: data, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return dio.patch(endpoint, data: data, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return dio.delete(endpoint, data: data, queryParameters: queryParameters);
  }
}

class ConnectionTestResult {
  final bool isSuccess;
  final int statusCode;
  final int latencyMs;
  final String message;
  final String testedUrl;
  final String? tenantDetected;
  final int? branchCount;
  final String? details;
  final bool usedFallback;

  ConnectionTestResult({
    required this.isSuccess,
    required this.statusCode,
    required this.latencyMs,
    required this.message,
    required this.testedUrl,
    this.tenantDetected,
    this.branchCount,
    this.details,
    this.usedFallback = false,
  });
}
