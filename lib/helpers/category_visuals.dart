import 'package:flutter/material.dart';

class CategoryVisuals {
  static const Map<String, String> _defaultImages = {
    'fitness':
        'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400&q=80',
    'beauty':
        'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400&q=80',
    'bags':
        'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400&q=80',
    'electronics':
        'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=400&q=80',
    'accessories':
        'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&q=80',
    'food':
        'https://images.unsplash.com/photo-1506617420156-8e4536971650?w=400&q=80',
    'watches':
        'https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=400&q=80',
    'footwear':
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&q=80',
    'clothing':
        'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=400&q=80',
    'household':
        'https://images.unsplash.com/photo-1583947215259-38e31be8751f?w=400&q=80',
    'pantry':
        'https://images.unsplash.com/photo-1584992236310-6edddc08acff?w=400&q=80',
    'beverages':
        'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=400&q=80',
    'fruits':
        'https://images.unsplash.com/photo-1619566629038-800d4f707c0d?w=400&q=80',
    'vegetables':
        'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400&q=80',
    'dairy':
        'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400&q=80',
    'bakery':
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&q=80',
    'snacks':
        'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=400&q=80',
    'meat':
        'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=400&q=80',
  };

  static String getEffectiveImage(String? currentImage, String categoryName) {
    if (currentImage != null && currentImage.trim().isNotEmpty) {
      return currentImage.trim();
    }
    final key = categoryName.toLowerCase().trim();
    for (final entry in _defaultImages.entries) {
      if (key.contains(entry.key)) {
        return entry.value;
      }
    }
    return '';
  }

  static IconData getIcon(String categoryName) {
    final lower = categoryName.toLowerCase().trim();
    if (lower.contains('fitness') ||
        lower.contains('gym') ||
        lower.contains('sport')) {
      return Icons.fitness_center_rounded;
    }
    if (lower.contains('beauty') ||
        lower.contains('cosmetic') ||
        lower.contains('skin')) {
      return Icons.spa_rounded;
    }
    if (lower.contains('bag')) {
      return Icons.shopping_bag_rounded;
    }
    if (lower.contains('electronic') ||
        lower.contains('tech') ||
        lower.contains('device')) {
      return Icons.devices_rounded;
    }
    if (lower.contains('accessori')) {
      return Icons.watch_rounded;
    }
    if (lower.contains('food') || lower.contains('meal')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('watch')) {
      return Icons.watch_outlined;
    }
    if (lower.contains('footwear') || lower.contains('shoe')) {
      return Icons.hiking_rounded;
    }
    if (lower.contains('cloth') || lower.contains('fashion')) {
      return Icons.checkroom_rounded;
    }
    if (lower.contains('household') || lower.contains('home')) {
      return Icons.cleaning_services_rounded;
    }
    if (lower.contains('pantry') || lower.contains('kitchen')) {
      return Icons.kitchen_rounded;
    }
    if (lower.contains('beverage') || lower.contains('drink')) {
      return Icons.local_drink_rounded;
    }
    if (lower.contains('fruit')) {
      return Icons.apple_rounded;
    }
    if (lower.contains('vegetable') || lower.contains('veg')) {
      return Icons.eco_rounded;
    }
    if (lower.contains('dairy') || lower.contains('milk')) {
      return Icons.egg_alt_rounded;
    }
    if (lower.contains('bakery') || lower.contains('bread')) {
      return Icons.bakery_dining_rounded;
    }
    if (lower.contains('snack')) {
      return Icons.cookie_rounded;
    }
    if (lower.contains('meat') ||
        lower.contains('beef') ||
        lower.contains('chicken')) {
      return Icons.kebab_dining_rounded;
    }
    return Icons.grid_view_rounded;
  }
}
