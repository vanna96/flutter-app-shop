class BannerModel {
  final int id;
  final String image;
  final String? title;
  final String? subtitle;
  final String? badge;
  final String? discount;
  final String? gradient;
  final String? mediaType;
  final String? tag;
  final String? icon;
  final String? badgeBg;
  final String? badgeColor;

  BannerModel({
    required this.id,
    required this.image,
    this.title,
    this.subtitle,
    this.badge,
    this.discount,
    this.gradient,
    this.mediaType,
    this.tag,
    this.icon,
    this.badgeBg,
    this.badgeColor,
  });

  bool get isNetworkImage {
    final trimmed = image.trim();
    return trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('//');
  }

  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';
  bool get isGradient => mediaType == 'gradient';

  String? get youtubeVideoId {
    if (!isVideo) return null;

    final uri = Uri.tryParse(image.trim());
    if (uri == null) return null;
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');

    String? candidate;
    if (host == 'youtu.be') {
      candidate = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    } else if (host == 'youtube.com' ||
        host == 'm.youtube.com' ||
        host == 'music.youtube.com' ||
        host == 'youtube-nocookie.com') {
      candidate = uri.queryParameters['v'];
      if (candidate == null &&
          uri.pathSegments.length >= 2 &&
          const {'shorts', 'embed', 'live'}.contains(uri.pathSegments.first)) {
        candidate = uri.pathSegments[1];
      }
    }

    if (candidate == null ||
        !RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(candidate)) {
      return null;
    }
    return candidate;
  }

  bool get isYouTubeVideo => youtubeVideoId != null;

  String? get webVideoUrl {
    if (!isVideo || isYouTubeVideo || hasPlayableVideoUrl) return null;

    final source = Uri.tryParse(image.trim());
    if (source == null ||
        !const {'http', 'https'}.contains(source.scheme) ||
        source.host.isEmpty) {
      return null;
    }

    final lowerPath = source.path.toLowerCase();
    if (RegExp(r'\.(?:avif|gif|jpe?g|png|svg|webp)$').hasMatch(lowerPath)) {
      return null;
    }

    final host = source.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    if (host == 'facebook.com' ||
        host == 'm.facebook.com' ||
        host == 'fb.watch') {
      return Uri.https('www.facebook.com', '/plugins/video.php', {
        'href': source.toString(),
        'show_text': 'false',
        'autoplay': 'true',
        'allowfullscreen': 'true',
      }).toString();
    }

    if (host == 'tiktok.com' ||
        host == 'm.tiktok.com' ||
        host == 'vm.tiktok.com' ||
        host == 'vt.tiktok.com') {
      final videoIndex = source.pathSegments.indexOf('video');
      final postId =
          videoIndex >= 0 && videoIndex + 1 < source.pathSegments.length
          ? source.pathSegments[videoIndex + 1]
          : null;
      if (postId != null && RegExp(r'^\d+$').hasMatch(postId)) {
        return Uri.https('www.tiktok.com', '/player/v1/$postId', {
          'autoplay': '1',
          'loop': '1',
          'muted': '1',
          'controls': '1',
        }).toString();
      }
    }

    // Other provider pages get a best-effort in-app WebView. Providers may
    // still refuse embedding for private, login-only, or restricted posts.
    return source.toString();
  }

  bool get hasPlayableVideoUrl {
    if (!isVideo) return false;

    final uri = Uri.tryParse(image);
    if (uri == null) return false;
    final path = uri.path.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.m3u8') ||
        path.endsWith('.mov') ||
        path.endsWith('.webm');
  }

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    String imageCandidate = '';
    final raw =
        json['image_url'] ??
        json['image'] ??
        json['media_url'] ??
        json['mediaUrl'];
    if (raw is String && raw.trim().isNotEmpty) {
      imageCandidate = _unwrapMarkdownUrl(raw.trim());
    } else if (raw is Map &&
        raw['url'] != null &&
        raw['url'].toString().trim().isNotEmpty) {
      imageCandidate = _unwrapMarkdownUrl(raw['url'].toString().trim());
    }

    final id = int.tryParse(json['id'].toString()) ?? 0;
    final rawMediaType =
        (json['media_type'] ?? json['mediaType'] ?? json['type'])
            ?.toString()
            .trim()
            .toLowerCase();
    final mediaType =
        const {'image', 'video', 'gradient'}.contains(rawMediaType)
        ? rawMediaType!
        : 'image';

    return BannerModel(
      id: id,
      image: imageCandidate,
      title: json['title']?.toString(),
      subtitle: json['subtitle']?.toString(),
      badge: json['badge']?.toString(),
      discount: json['discount']?.toString(),
      gradient: json['gradient']?.toString(),
      mediaType: mediaType,
      tag: json['tag']?.toString(),
      icon: json['icon']?.toString(),
      badgeBg: (json['badgeBg'] ?? json['badge_bg'])?.toString(),
      badgeColor: (json['badgeColor'] ?? json['badge_color'])?.toString(),
    );
  }

  static String _unwrapMarkdownUrl(String value) {
    final match = RegExp(r'^\[[^\]]*\]\((https?://[^)]+)\)$').firstMatch(value);
    return match?.group(1)?.replaceAll(r'\&', '&') ?? value;
  }
}
