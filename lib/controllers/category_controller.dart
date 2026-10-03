import 'package:get/get.dart';
import 'package:grocery_app/controllers/store_controller.dart';
import 'package:grocery_app/data/mock_data.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/services/mobile_api_repository.dart';

class CategoryController extends GetxController {
  var isLoading = true.obs;
  final MobileApiRepository _mobileApiRepository = MobileApiRepository();

  RxList<CategoryModel> categories = <CategoryModel>[].obs;

  @override
  void onInit() {
    fetchInitData();
    super.onInit();

    if (Get.isRegistered<StoreController>()) {
      ever(Get.find<StoreController>().selectedLocationId, (_) {
        fetchInitData();
      });
    }
  }

  Future<void> fetchInitData() async {
    try {
      isLoading.value = true;
      int? branchId;
      if (Get.isRegistered<StoreController>()) {
        final locId = Get.find<StoreController>().selectedLocationId.value;
        if (locId > 0) {
          branchId = locId;
        }
      }

      final remoteCategories =
          await _mobileApiRepository.fetchCategories(branchId: branchId);
      if (remoteCategories.isNotEmpty) {
        MockDataRepository.updateCategories(remoteCategories);
      }
      categories.value =
          List<CategoryModel>.from(MockDataRepository.categories);
    } catch (e) {
      categories.value =
          List<CategoryModel>.from(MockDataRepository.categories);
      print('ERROR: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
