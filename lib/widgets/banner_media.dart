import 'package:grocery_app/localization/localized_material.dart';
import 'package:grocery_app/models/banner_model.dart';
import 'package:grocery_app/widgets/app_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class BannerMedia extends StatelessWidget {
  const BannerMedia({
    super.key,
    required this.banner,
    required this.fallbackColors,
  });

  final BannerModel banner;
  final List<Color> fallbackColors;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: bannerGradient(banner.gradient, fallbackColors),
      ),
    );

    if (banner.isGradient || banner.image.trim().isEmpty) {
      return fallback;
    }

    if (banner.isVideo) {
      final youtubeVideoId = banner.youtubeVideoId;
      if (youtubeVideoId != null) {
        return Stack(
          fit: StackFit.expand,
          children: [
            fallback,
            _YoutubeBannerVideo(
              key: ValueKey('${banner.id}-$youtubeVideoId'),
              videoId: youtubeVideoId,
            ),
          ],
        );
      }

      if (banner.hasPlayableVideoUrl) {
        return Stack(
          fit: StackFit.expand,
          children: [
            fallback,
            _NetworkBannerVideo(
              key: ValueKey('${banner.id}-${banner.image}'),
              url: banner.image,
            ),
          ],
        );
      }

      final webVideoUrl = banner.webVideoUrl;
      if (webVideoUrl != null) {
        return Stack(
          fit: StackFit.expand,
          children: [
            fallback,
            _EmbeddedWebBannerVideo(
              key: ValueKey('${banner.id}-$webVideoUrl'),
              embedUrl: webVideoUrl,
              sourceUrl: banner.image,
            ),
          ],
        );
      }

      // Some API records use a still image as the video poster. Keep that
      // useful fallback visible, but make the selected media type apparent.
      return Stack(
        fit: StackFit.expand,
        children: [
          fallback,
          AppNetworkImage(image: banner.image, fit: BoxFit.cover),
          Center(
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.48),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        fallback,
        AppNetworkImage(image: banner.image, fit: BoxFit.cover),
      ],
    );
  }
}

class _EmbeddedWebBannerVideo extends StatefulWidget {
  const _EmbeddedWebBannerVideo({
    super.key,
    required this.embedUrl,
    required this.sourceUrl,
  });

  final String embedUrl;
  final String sourceUrl;

  @override
  State<_EmbeddedWebBannerVideo> createState() =>
      _EmbeddedWebBannerVideoState();
}

class _EmbeddedWebBannerVideoState extends State<_EmbeddedWebBannerVideo> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if ((error.isForMainFrame ?? false) && mounted) {
              setState(() {
                _isLoading = false;
                _failed = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.embedUrl));
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.sourceUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Material(
        color: Colors.black26,
        child: InkWell(
          onTap: _openExternally,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.open_in_new_rounded, color: Colors.white, size: 30),
                SizedBox(height: 4),
                Text(
                  'Open video',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const ColoredBox(
            color: Colors.black26,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _YoutubeBannerVideo extends StatefulWidget {
  const _YoutubeBannerVideo({super.key, required this.videoId});

  final String videoId;

  @override
  State<_YoutubeBannerVideo> createState() => _YoutubeBannerVideoState();
}

class _YoutubeBannerVideoState extends State<_YoutubeBannerVideo> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        mute: true,
        loop: true,
        playsInline: true,
        showControls: true,
        showFullscreenButton: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final aspectRatio = width > 0 && height > 0 ? width / height : 16 / 9;
        return YoutubePlayer(controller: _controller, aspectRatio: aspectRatio);
      },
    );
  }
}

class _NetworkBannerVideo extends StatefulWidget {
  const _NetworkBannerVideo({super.key, required this.url});

  final String url;

  @override
  State<_NetworkBannerVideo> createState() => _NetworkBannerVideoState();
}

class _NetworkBannerVideoState extends State<_NetworkBannerVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final resolvedUrl = AppNetworkImage.resolveImageUrl(widget.url);
    final uri = Uri.tryParse(resolvedUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('[BannerMedia] Video failed for $resolvedUrl: $error');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed) {
      return const Center(
        child: Icon(
          Icons.videocam_off_rounded,
          color: Colors.white70,
          size: 34,
        ),
      );
    }
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    final size = controller.value.size;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

LinearGradient bannerGradient(String? css, List<Color> fallbackColors) {
  final colors = _colorsFromCss(css);
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: colors.length >= 2 ? colors : fallbackColors,
  );
}

Color? bannerColor(String? css) {
  if (css == null) return null;
  final value = css.trim().toLowerCase();
  if (value.isEmpty) return null;

  if (value.startsWith('#')) {
    final hex = value.substring(1);
    if (hex.length == 3 || hex.length == 4) {
      final expanded = hex.split('').map((digit) => '$digit$digit').join();
      return bannerColor('#$expanded');
    }
    if (hex.length == 6) {
      final parsed = int.tryParse(hex, radix: 16);
      return parsed == null ? null : Color(0xFF000000 | parsed);
    }
    if (hex.length == 8) {
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed == null) return null;
      final rgb = parsed >> 8;
      final alpha = parsed & 0xFF;
      return Color((alpha << 24) | rgb);
    }
    return null;
  }

  final match = RegExp(
    r'^rgba?\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})(?:\s*,\s*([\d.]+))?\s*\)$',
  ).firstMatch(value);
  if (match == null) return null;

  final red = int.parse(match.group(1)!).clamp(0, 255);
  final green = int.parse(match.group(2)!).clamp(0, 255);
  final blue = int.parse(match.group(3)!).clamp(0, 255);
  final alphaValue = double.tryParse(match.group(4) ?? '1') ?? 1;
  final alpha = (alphaValue.clamp(0.0, 1.0) * 255).round();
  return Color.fromARGB(alpha, red, green, blue);
}

List<Color> _colorsFromCss(String? css) {
  if (css == null || css.trim().isEmpty) return const [];

  final matches = RegExp(r'#[0-9a-fA-F]{3,8}|rgba?\([^)]*\)').allMatches(css);
  return matches
      .map((match) => bannerColor(match.group(0)))
      .whereType<Color>()
      .toList(growable: false);
}
