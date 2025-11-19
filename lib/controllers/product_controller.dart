import 'package:get/get.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/services/api_service.dart';

class ProductController extends GetxController {
  var isLoading = true.obs;

  RxList<ProductModel> newP = <ProductModel>[].obs;
  RxList<ProductModel> best_sell = <ProductModel>[].obs;
  RxList<ProductModel> best_sell2 = <ProductModel>[].obs;

  @override
  void onInit() {
    fetchInitData();
    super.onInit();
  }

  Future<void> fetchInitData() async {
    try {
      isLoading.value = true;

      final newRes = await ApiService().get('/api/product/new?page=1&store_id=1');
      final bestSellRes = await ApiService().get('/api/product/new?page=1&store_id=1');
      final bestSellRes2 = await ApiService().get('/api/product/new?page=2&store_id=1');

      final newList = newRes.data['data'] as List;
      final bestSell = bestSellRes.data['data'] as List;
      final bestSell2 = bestSellRes2.data['data'] as List;

      // Map JSON to models
      newP.value =
          newList.map((e) => ProductModel.fromJson(e)).toList();
      best_sell.value =
          bestSell.map((e) => ProductModel.fromJson(e)).toList();
      best_sell2.value =
          bestSell2.map((e) => ProductModel.fromJson(e)).toList();

    } catch (e) {
      print("ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
