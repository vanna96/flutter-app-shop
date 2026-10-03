import 'package:cached_network_image/cached_network_image.dart';
import 'package:grocery_app/localization/localized_material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grocery_app/services/api_service.dart';
import 'package:grocery_app/styles/colors.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.fallbackIcon,
    this.fallbackAsset,
  });

  final String image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData? fallbackIcon;
  final String? fallbackAsset;

  static String resolveImageUrl(String rawUrl) {
    final trimmed = rawUrl.trim().replaceAll(r'\', '/');
    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('assets/') || trimmed.startsWith('lib/')) {
      return trimmed;
    }

    try {
      final baseApiUrl = ApiService().dio.options.baseUrl;
      final apiUri = Uri.tryParse(baseApiUrl);
      if (apiUri == null || apiUri.host.isEmpty) {
        return trimmed;
      }

      final apiOrigin = Uri(
        scheme: apiUri.scheme.isNotEmpty ? apiUri.scheme : 'http',
        host: apiUri.host,
        port: apiUri.hasPort ? apiUri.port : null,
      );

      // Handle localhost rewrites for physical devices
      var candidate = trimmed;
      if ((candidate.contains('localhost') || candidate.contains('127.0.0.1')) &&
          apiUri.host != 'localhost' &&
          apiUri.host != '127.0.0.1') {
        candidate = candidate
            .replaceAll('localhost', apiUri.host)
            .replaceAll('127.0.0.1', apiUri.host);
      }

      if (candidate.startsWith('//')) {
        return '${apiOrigin.scheme}:$candidate';
      }

      final uri = Uri.tryParse(candidate);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        return candidate;
      }

      final relativePath = candidate.startsWith('/') ? candidate : '/$candidate';
      return apiOrigin.resolve(relativePath).toString();
    } catch (_) {}

    return trimmed;
  }

  String get _resolvedImageUrl => resolveImageUrl(image);

  bool get _isValidNetworkUrl {
    final trimmed = _resolvedImageUrl.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  bool get _isLocalAsset {
    final trimmed = image.trim();
    return trimmed.isNotEmpty &&
        (trimmed.startsWith('assets/') || trimmed.startsWith('lib/'));
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isValidNetworkUrl) {
      content = Image.network(
        _resolvedImageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _loadingWidget();
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
              '[AppNetworkImage] Image.network error for $_resolvedImageUrl: $error');
          return CachedNetworkImage(
            imageUrl: _resolvedImageUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: (_, __) => _loadingWidget(),
            errorWidget: (_, __, ___) => _fallbackOrPlaceholderWidget(),
          );
        },
      );
    } else if (_isLocalAsset) {
      content = Image.asset(
        image.trim(),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallbackOrPlaceholderWidget(),
      );
    } else {
      content = _fallbackOrPlaceholderWidget();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }

  Widget _fallbackOrPlaceholderWidget() {
    if (fallbackAsset != null && fallbackAsset!.trim().isNotEmpty) {
      return Image.asset(
        fallbackAsset!.trim(),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholderWidget(),
      );
    }
    return _placeholderWidget();
  }

  Widget _loadingWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: borderRadius ?? BorderRadius.circular(14),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _placeholderWidget() {
    if (fallbackIcon != null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: borderRadius ?? BorderRadius.circular(14),
        ),
        child: Center(
          child: Icon(
            fallbackIcon,
            color: const Color(0xFF94A3B8),
            size: 28,
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: borderRadius ?? BorderRadius.circular(14),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SvgPicture.asset(
            'assets/icons/no_order_placeholder.svg',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
