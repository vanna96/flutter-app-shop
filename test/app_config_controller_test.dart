import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_app/controllers/app_config_controller.dart';
import 'package:grocery_app/services/api_service.dart';

void main() {
  group('AppConfigController URL Sanitization and Resolution', () {
    test('preserves DuckDNS domain without modifying hostname and uses default /v1/api', () {
      final effective = AppConfigController.resolveEffectiveUrl(
        rawUrl: 'https://vanna-pos.duckdns.org',
        tenant: 'rechna',
      );
      expect(effective, 'https://vanna-pos.duckdns.org/v1/api');
    });

    test('supports custom apiPath such as /v2/api', () {
      final effective = AppConfigController.resolveEffectiveUrl(
        rawUrl: 'https://vanna-pos.duckdns.org',
        tenant: 'rechna',
        apiPath: '/v2/api',
      );
      expect(effective, 'https://vanna-pos.duckdns.org/v2/api');
    });

    test('preserves custom api path if included directly in rawUrl', () {
      final effective = AppConfigController.resolveEffectiveUrl(
        rawUrl: 'https://vanna-pos.duckdns.org/v2/api',
        tenant: 'rechna',
      );
      expect(effective, 'https://vanna-pos.duckdns.org/v2/api');
    });

    test('strips trailing slashes from domain and appends configured apiPath', () {
      final effective = AppConfigController.resolveEffectiveUrl(
        rawUrl: 'https://vanna-pos.duckdns.org/',
        tenant: 'rechna',
        apiPath: '/v2/api',
      );
      expect(effective, 'https://vanna-pos.duckdns.org/v2/api');
    });

    test('sanitizeBaseUrl preserves API paths like /v2/api and strips /mobile suffix', () {
      final sanitizedApi = AppConfigController.sanitizeBaseUrl(
        'https://vanna-pos.duckdns.org/v2/api',
      );
      expect(sanitizedApi, 'https://vanna-pos.duckdns.org/v2/api');

      final sanitizedMobile = AppConfigController.sanitizeBaseUrl(
        'https://vanna-pos.duckdns.org/v2/api/mobile',
      );
      expect(sanitizedMobile, 'https://vanna-pos.duckdns.org/v2/api');
    });

    test('preserves IP address and appends apiPath', () {
      final effective = AppConfigController.resolveEffectiveUrl(
        rawUrl: 'http://192.168.0.66:8880',
        tenant: 'rechna',
        apiPath: '/v2/api',
      );
      expect(effective, 'http://192.168.0.66:8880/v2/api');
    });

    test('preserves localhost as domain without adding subdomain', () {
      final effective = AppConfigController.resolveEffectiveUrl(
        rawUrl: 'http://localhost:8880',
        tenant: 'rechna',
      );
      expect(effective, 'http://localhost:8880/v1/api');
    });

    test('adds http:// scheme if omitted', () {
      final sanitized = AppConfigController.sanitizeBaseUrl(
        'vanna-pos.duckdns.org',
      );
      expect(sanitized, 'http://vanna-pos.duckdns.org');
    });

    test('ApiService.normalizeBaseUrl handles custom apiPath and existing paths', () {
      expect(
        ApiService.normalizeBaseUrl('https://vanna-pos.duckdns.org', apiPath: '/v2/api'),
        'https://vanna-pos.duckdns.org/v2/api',
      );
      expect(
        ApiService.normalizeBaseUrl('https://vanna-pos.duckdns.org/v2/api'),
        'https://vanna-pos.duckdns.org/v2/api',
      );
      expect(
        ApiService.normalizeBaseUrl('https://vanna-pos.duckdns.org/v2/api/mobile'),
        'https://vanna-pos.duckdns.org/v2/api',
      );
    });
  });
}
