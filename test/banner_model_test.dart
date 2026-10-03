import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_app/models/banner_model.dart';
import 'package:grocery_app/widgets/banner_media.dart';

void main() {
  group('BannerModel', () {
    test('normalizes the API type and recognizes playable video URLs', () {
      final banner = BannerModel.fromJson({
        'id': '6',
        'type': ' VIDEO ',
        'image_url': 'https://example.com/banner.mp4?version=2',
      });

      expect(banner.id, 6);
      expect(banner.mediaType, 'video');
      expect(banner.isVideo, isTrue);
      expect(banner.hasPlayableVideoUrl, isTrue);
    });

    test('keeps an image URL as a poster for a video record', () {
      final banner = BannerModel.fromJson({
        'id': 6,
        'type': 'video',
        'image_url': 'https://images.example.com/poster.jpg',
      });

      expect(banner.isVideo, isTrue);
      expect(banner.hasPlayableVideoUrl, isFalse);
    });

    test('extracts a YouTube Shorts video id', () {
      final banner = BannerModel.fromJson({
        'id': 6,
        'type': 'video',
        'image_url': 'https://www.youtube.com/shorts/_Y7neg6PUEg',
      });

      expect(banner.isYouTubeVideo, isTrue);
      expect(banner.youtubeVideoId, '_Y7neg6PUEg');
    });

    test('supports common YouTube URL formats', () {
      const videoId = '_Y7neg6PUEg';
      final urls = [
        'https://youtube.com/watch?v=$videoId',
        'https://youtu.be/$videoId',
        'https://youtube.com/embed/$videoId',
        'https://youtube.com/live/$videoId',
        'https://music.youtube.com/watch?v=$videoId',
      ];

      for (final url in urls) {
        final banner = BannerModel.fromJson({
          'id': 6,
          'type': 'video',
          'image_url': url,
        });
        expect(banner.youtubeVideoId, videoId, reason: url);
      }
    });

    test('creates an official TikTok player URL from a post URL', () {
      final banner = BannerModel.fromJson({
        'id': 8,
        'type': 'video',
        'image_url':
            'https://www.tiktok.com/@creator/video/6718335390845095173',
      });

      final embed = Uri.parse(banner.webVideoUrl!);
      expect(embed.host, 'www.tiktok.com');
      expect(embed.path, '/player/v1/6718335390845095173');
      expect(embed.queryParameters['autoplay'], '1');
      expect(embed.queryParameters['controls'], '1');
    });

    test('creates a Facebook video plugin URL', () {
      const source = 'https://www.facebook.com/example/videos/123456789/';
      final banner = BannerModel.fromJson({
        'id': 9,
        'type': 'video',
        'image_url': source,
      });

      final embed = Uri.parse(banner.webVideoUrl!);
      expect(embed.host, 'www.facebook.com');
      expect(embed.path, '/plugins/video.php');
      expect(embed.queryParameters['href'], source);
      expect(embed.queryParameters['autoplay'], 'true');
    });

    test('defaults an unknown or missing type to image', () {
      final banner = BannerModel.fromJson({
        'id': 5,
        'type': 'unsupported',
        'image_url': 'https://example.com/banner.png',
      });

      expect(banner.mediaType, 'image');
      expect(banner.isImage, isTrue);
    });

    test('unwraps a markdown-formatted URL defensively', () {
      final banner = BannerModel.fromJson({
        'id': 5,
        'type': 'image',
        'image_url': '[preview](https://example.com/banner.png?a=1\\&b=2)',
      });

      expect(banner.image, 'https://example.com/banner.png?a=1&b=2');
    });
  });

  group('banner styling', () {
    test('parses rgba API colors', () {
      expect(
        bannerColor('rgba(34, 197, 94, 0.95)')?.toARGB32(),
        const Color.fromARGB(242, 34, 197, 94).toARGB32(),
      );
    });

    test('parses all colors from a CSS linear gradient', () {
      final gradient = bannerGradient(
        'linear-gradient(135deg, #15803d 0%, #16a34a 50%, #22c55e 100%)',
        const [Colors.black, Colors.white],
      );

      expect(gradient.colors, const [
        Color(0xFF15803D),
        Color(0xFF16A34A),
        Color(0xFF22C55E),
      ]);
    });
  });
}
