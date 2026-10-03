import 'dart:async';
import 'package:get/get.dart';
import 'package:grocery_app/controllers/banner_controller.dart';
import 'package:grocery_app/controllers/category_controller.dart';
import 'package:grocery_app/controllers/product_controller.dart';
import 'package:grocery_app/controllers/store_controller.dart';
import 'package:grocery_app/services/api_service.dart';

class NetworkStatusController extends GetxController {
  final RxBool isUnavailable = false.obs;
  final RxBool isRetrying = false.obs;
  final RxString message = 'No internet connection'.obs;
  final RxBool showBackOnline = false.obs;
  final RxBool isDismissed = false.obs;

  Timer? _backOnlineTimer;
  bool _wasEverOffline = false;

  void markAvailable() {
    if (isUnavailable.value || _wasEverOffline) {
      // Transition from offline to online
      showBackOnline.value = true;
      _backOnlineTimer?.cancel();
      _backOnlineTimer = Timer(const Duration(milliseconds: 2800), () {
        showBackOnline.value = false;
      });
      _wasEverOffline = false;
    }
    isUnavailable.value = false;
    isDismissed.value = false;
  }

  void markUnavailable([String? reason]) {
    _backOnlineTimer?.cancel();
    showBackOnline.value = false;
    _wasEverOffline = true;
    message.value = reason?.trim().isNotEmpty == true
        ? reason!.trim()
        : 'No internet connection';
    isUnavailable.value = true;
    isDismissed.value = false;
  }

  void dismiss() {
    isDismissed.value = true;
  }

  void setRetrying(bool value) {
    isRetrying.value = value;
  }

  Future<bool> retry() async {
    if (isRetrying.value) return false;

    setRetrying(true);
    try {
      await ApiService().get('/mobile/branches');
      markAvailable();

      await Future.wait([
        if (Get.isRegistered<StoreController>())
          Get.find<StoreController>().fetchInitData(),
        if (Get.isRegistered<CategoryController>())
          Get.find<CategoryController>().fetchInitData(),
        if (Get.isRegistered<BannerController>())
          Get.find<BannerController>().fetchInitData(),
        if (Get.isRegistered<ProductController>())
          Get.find<ProductController>().fetchInitData(),
      ]);
      return true;
    } catch (_) {
      markUnavailable('No internet connection or server unavailable');
      return false;
    } finally {
      setRetrying(false);
    }
  }

  @override
  void onClose() {
    _backOnlineTimer?.cancel();
    super.onClose();
  }
}

