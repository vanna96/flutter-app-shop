import 'package:flutter/material.dart';
import 'package:grocery_app/screens/splash_screen.dart';
import 'package:grocery_app/styles/theme.dart';
import 'package:grocery_app/widgets/network_status_banner.dart';
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
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'V-POS',
        theme: buildThemeData(languageController.currentLanguageCode.value),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        locale: Locale(languageController.currentLanguageCode.value),
        builder: (context, child) => Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => ScaffoldMessenger(
                child: Stack(
                  textDirection: TextDirection.ltr,
                  children: [
                    child ?? const SizedBox.shrink(),
                    const NetworkStatusBanner(),
                  ],
                ),
              ),
            ),
          ],
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
