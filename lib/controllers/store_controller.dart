import 'package:get/get.dart';
import 'package:grocery_app/controllers/banner_controller.dart';
import 'package:grocery_app/controllers/category_controller.dart';
import 'package:grocery_app/controllers/product_controller.dart';
import 'package:grocery_app/data/mock_data.dart';
import 'package:grocery_app/models/store_model.dart';
import 'package:grocery_app/services/mobile_api_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreController extends GetxController {
  var isLoading = true.obs;
  final MobileApiRepository _mobileApiRepository = MobileApiRepository();

  // Stores list
  RxList<StoreModel> stores = <StoreModel>[].obs;

  // Selected store ID: 0 means All Branches
  RxInt selectedLocationId = 0.obs;

  bool get isAllBranches => selectedLocationId.value == 0;

  StoreModel? get selectedStore {
    final id = selectedLocationId.value;
    if (id == 0) return null;
    return stores.firstWhereOrNull((store) => store.id == id);
  }

  @override
  void onInit() {
    fetchInitData();
    super.onInit();
  }

  Future<void> fetchInitData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getInt('store_id');

    try {
      isLoading.value = true;
      final remoteStores = await _mobileApiRepository.fetchBranches();
      if (remoteStores.isNotEmpty) {
        MockDataRepository.updateStores(remoteStores);
      }
      stores.value = List<StoreModel>.from(MockDataRepository.stores);
    } catch (e) {
      stores.value = List<StoreModel>.from(MockDataRepository.stores);
      print('ERROR: $e');
    } finally {
      final resolvedId =
          savedId != null &&
              (savedId == 0 || stores.any((store) => store.id == savedId))
          ? savedId
          : 0;
      selectedLocationId.value = resolvedId;

      isLoading.value = false;
    }
  }

  Future<void> updateSelectedStore(int id) async {
    selectedLocationId.value = id;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('store_id', id);

    // Refresh all screens and controllers based on new branch
    if (Get.isRegistered<ProductController>()) {
      Get.find<ProductController>().fetchInitData();
    }
    if (Get.isRegistered<BannerController>()) {
      Get.find<BannerController>().fetchInitData();
    }
    if (Get.isRegistered<CategoryController>()) {
      Get.find<CategoryController>().fetchInitData();
    }
  }
}
