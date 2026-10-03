import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grocery_app/controllers/app_config_controller.dart';
import 'package:grocery_app/controllers/app_state_controller.dart';
import 'package:grocery_app/controllers/language_controller.dart';
import 'package:grocery_app/controllers/network_status_controller.dart';
import 'controllers/login_controller.dart';
import 'package:grocery_app/controllers/store_controller.dart';
import 'package:grocery_app/controllers/category_controller.dart';
import 'package:grocery_app/controllers/product_controller.dart';
import 'package:grocery_app/controllers/banner_controller.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  Get.put(NetworkStatusController(), permanent: true);
  Get.put(LoginController(), permanent: true);
  Get.put(LanguageController(), permanent: true);
  Get.put(AppConfigController(), permanent: true);
  Get.put(AppStateController(), permanent: true);
  Get.put(StoreController(), permanent: true);
  Get.put(CategoryController(), permanent: true);
  Get.put(ProductController(), permanent: true);
  Get.put(BannerController(), permanent: true);

  runApp(const MyApp());
}
