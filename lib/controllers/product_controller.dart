import 'package:get/get.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/services/api_service.dart';
import 'package:grocery_app/controllers/store_controller.dart';

class ProductController extends GetxController {
  var isLoading = true.obs;

  final StoreController storeController = Get.find<StoreController>();

  RxList<ProductModel> newP = <ProductModel>[].obs;
  RxList<ProductModel> best_sell = <ProductModel>[].obs;
  RxList<ProductModel> best_sell2 = <ProductModel>[].obs;

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
}
