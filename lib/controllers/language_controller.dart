import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

class LanguageController extends GetxController {
  final _storage = GetStorage();
  var currentLanguage = 'English'.obs;
  var currentLanguageCode = 'en'.obs;

  @override
  void onInit() {
    super.onInit();
    // Load saved language
    currentLanguage.value = _storage.read('language') ?? 'English';
    currentLanguageCode.value = _storage.read('languageCode') ?? 'en';
  }

  void setLanguage(String language, String code) {
    currentLanguage.value = language;
    currentLanguageCode.value = code;

    // Persist
    _storage.write('language', language);
    _storage.write('languageCode', code);

    // Update locale
    Get.updateLocale(Locale(code));
  }
}
