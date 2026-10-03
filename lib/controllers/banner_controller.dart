import 'package:get/get.dart';
import 'package:grocery_app/controllers/store_controller.dart';
import 'package:grocery_app/data/mock_data.dart';
import 'package:grocery_app/models/banner_model.dart';
import 'package:grocery_app/services/mobile_api_repository.dart';

class BannerController extends GetxController {
  var isLoading = true.obs;
  final MobileApiRepository _mobileApiRepository = MobileApiRepository();
  int _requestSequence = 0;

  RxList<BannerModel> banners = <BannerModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    if (MockDataRepository.hasRemoteBanners) {
      banners.assignAll(MockDataRepository.banners);
      isLoading.value = false;
    } else {
      isLoading.value = true;
    }
    fetchInitData();

    if (Get.isRegistered<StoreController>()) {
      ever(Get.find<StoreController>().selectedLocationId, (_) {
        fetchInitData();
      });
    }
  }

  Future<void> fetchInitData() async {
    final requestId = ++_requestSequence;
    try {
      isLoading.value = banners.isEmpty;
      int? branchId;
      if (Get.isRegistered<StoreController>()) {
        final locId = Get.find<StoreController>().selectedLocationId.value;
        if (locId > 0) {
          branchId = locId;
        }
      }

      final remoteBanners =
          await _mobileApiRepository.fetchBanners(branchId: branchId);
      if (requestId != _requestSequence) return;

      MockDataRepository.updateBanners(remoteBanners);
      banners.assignAll(remoteBanners);
    } catch (e) {
      print('[BannerController] fetchInitData error: $e');
    } finally {
      if (requestId == _requestSequence) {
        isLoading.value = false;
      }
    }
  }
}
