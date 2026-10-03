import 'package:flutter/material.dart';
import 'package:grocery_app/styles/colors.dart';

const String gilroyFontFamily = 'Gilroy';
const String khmerFontFamily = 'NotoSansKhmer';

ThemeData buildThemeData(String languageCode) {
  final fontFamily = languageCode == 'km' ? khmerFontFamily : gilroyFontFamily;

  return ThemeData(
    fontFamily: fontFamily,
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: Colors.white,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: AppColors.primaryColor,
      secondary: AppColors.primaryColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}
