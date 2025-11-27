import 'package:flutter/material.dart';
import 'package:demo_app/screens/splash_screen.dart';
import 'package:demo_app/styles/theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'controllers/language_controller.dart';
import 'generated/l10n.dart';

import 'package:get/get.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final LanguageController languageController =
        Get.find<LanguageController>();
    return Obx(
      () => MaterialApp(
        theme: themeData,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        locale: Locale(languageController.currentLanguageCode.value),
        home: SplashScreen(),
      ),
    );
  }
}
