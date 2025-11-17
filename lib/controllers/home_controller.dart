import 'package:get/get.dart';
import 'package:grocery_app/models/banner_model.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/services/api_service.dart';

class HomeController extends GetxController {
  var isLoading = true.obs;

  RxList<BannerModel> banners = <BannerModel>[].obs;
  RxList<CategoryModel> categories = <CategoryModel>[].obs;
  RxList<ProductModel> newP = <ProductModel>[].obs;
  RxList<ProductModel> best_sell = <ProductModel>[].obs;
  RxList<ProductModel> best_sell2 = <ProductModel>[].obs;
  RxList stores = <dynamic>[].obs;

  @override
  void onInit() {
    print('HomeController onInit called');
    fetchHomeData();
    super.onInit();
  }

  Future<void> fetchHomeData() async {
    try {
      isLoading.value = true;

      final bannerRes = await ApiService().get('/api/slider');
      final categoryRes = await ApiService().get('/api/category');
      final newRes = await ApiService().get('/api/product/new?page=1&store_id=1');
      final bestSellRes = await ApiService().get('/api/product/new?page=1&store_id=1');
      final bestSellRes2 = await ApiService().get('/api/product/new?page=2&store_id=1');
      final storeRes = await ApiService().get('/api/store');


      // Access the data inside Response.data
      final bannerList = bannerRes.data['data'] as List;
      final categoryList = categoryRes.data['data'] as List;
      final newList = newRes.data['data'] as List;
      final bestSell = bestSellRes.data['data'] as List;
      final bestSell2 = bestSellRes2.data['data'] as List;
      final storesList = storeRes.data['data'] as List;

      // Map JSON to models
      banners.value =
          bannerList.map((e) => BannerModel.fromJson(e)).toList();
      categories.value =
          categoryList.map((e) => CategoryModel.fromJson(e)).toList();
      newP.value =
          newList.map((e) => ProductModel.fromJson(e)).toList();
      best_sell.value =
          bestSell.map((e) => ProductModel.fromJson(e)).toList();
      best_sell2.value =
          bestSell2.map((e) => ProductModel.fromJson(e)).toList();

      stores.value = List<Map<String, dynamic>>.from(storesList);

    } catch (e) {
      print("ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
