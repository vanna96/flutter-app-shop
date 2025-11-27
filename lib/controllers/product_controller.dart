import 'package:get/get.dart';
import 'package:demo_app/models/product_model.dart';
import 'package:demo_app/services/api_service.dart';
import 'package:demo_app/controllers/store_controller.dart';

class ProductController extends GetxController {
  var isLoading = true.obs;
  var page = 1.obs; // current page
  var hasMore = true.obs; // track if more data exists
  int? _currentCategoryId;

  final StoreController storeController = Get.find<StoreController>();

  RxList<ProductModel> newP = <ProductModel>[].obs;
  RxList<ProductModel> best_sell = <ProductModel>[].obs;
  RxList<ProductModel> best_sell2 = <ProductModel>[].obs;
  RxList<ProductModel> productByCategory = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();

    // First load
    fetchInitData();

    // Auto-refresh when store changes
    ever(storeController.selectedLocationId, (_) {
      fetchInitData();
    });
  }

  Future<void> fetchInitData() async {
    try {
      isLoading.value = true;

      final id = storeController.selectedLocationId.value;

      final newRes = await ApiService().get('/api/product/new?page=1&store_id=$id');
      final bestSellRes = await ApiService().get('/api/product/new?page=1&store_id=$id');
      final bestSellRes2 = await ApiService().get('/api/product/new?page=2&store_id=$id');

      final newList = newRes.data['data'] as List;
      final bestSell = bestSellRes.data['data'] as List;
      final bestSell2 = bestSellRes2.data['data'] as List;

      newP.value = newList.map((e) => ProductModel.fromJson(e)).toList();
      best_sell.value = bestSell.map((e) => ProductModel.fromJson(e)).toList();
      best_sell2.value = bestSell2.map((e) => ProductModel.fromJson(e)).toList();

    } catch (e) {
      print("ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getProductByCategory(int catId, {bool reset = false}) async {
    try {
      if (reset || _currentCategoryId != catId) {
        page.value = 1;
        hasMore.value = true;
        productByCategory.clear();
        _currentCategoryId = catId; // track current category
      }

      if (!hasMore.value) return;

      isLoading.value = true;
      final storeId = storeController.selectedLocationId.value;

      final res = await ApiService().get(
          '/api/products?store_id=$storeId&category_id=$catId&page=${page.value}');

      final list = res.data['data'] as List;

      print('category ${catId}');
      print('page ${page.value}');

      if (list.isEmpty) {
        hasMore.value = false;
      } else {
        productByCategory.addAll(list.map((e) => ProductModel.fromJson(e)));
        page.value += 1;
      }
    } catch (e) {
      print("ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
