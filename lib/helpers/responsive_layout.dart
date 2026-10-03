import 'dart:math' as math;

import 'package:flutter/material.dart';

class ResponsiveLayout {
  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 700;
  }

  static bool isLargeTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 1100;
  }

  static double horizontalPadding(BuildContext context) {
    if (isLargeTablet(context)) {
      return 40;
    }

    if (isTablet(context)) {
      return 28;
    }

    return 20;
  }

  static double maxContentWidth(
    BuildContext context, {
    double tablet = 920,
    double largeTablet = 1180,
  }) {
    if (isLargeTablet(context)) {
      return largeTablet;
    }

    if (isTablet(context)) {
      return tablet;
    }

    return double.infinity;
  }

  static int gridColumns(
    BuildContext context, {
    double minTileWidth = 180,
    int mobileColumns = 2,
    int maxColumns = 4,
  }) {
    if (!isTablet(context)) {
      return mobileColumns;
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = maxContentWidth(context);
    final usableWidth =
        math.min(screenWidth, maxWidth) - (horizontalPadding(context) * 2);

    return math.max(
      mobileColumns,
      math.min(maxColumns, (usableWidth / minTileWidth).floor()),
    );
  }

  static double productGridAspectRatio(BuildContext context) {
    return isTablet(context) ? 0.74 : 0.60;
  }

  static double productCarouselCardWidth(BuildContext context) {
    if (isLargeTablet(context)) {
      return 250;
    }

    if (isTablet(context)) {
      return 220;
    }

    return 196;
  }

  static double featuredCategoryCardWidth(BuildContext context) {
    if (isLargeTablet(context)) {
      return 96;
    }

    if (isTablet(context)) {
      return 88;
    }

    return 76;
  }
}
