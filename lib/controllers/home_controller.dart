import 'package:get/get.dart';
import 'package:grocery_app/models/banner_model.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/services/api_service.dart';

class HomeController extends GetxController {
  var isLoading = true.obs;

  RxList<BannerModel> banners = <BannerModel>[].obs;
  RxList<CategoryModel> categories = <CategoryModel>[].obs;
  RxList<ProductModel> products = <ProductModel>[].obs;

  @override
  void onInit() {
    fetchHomeData();
    super.onInit();
  }

  Future<void> fetchHomeData() async {
    try {
      isLoading.value = true;

      final bannerRes = await ApiService().get('/api/slider');
      final categoryRes = await ApiService().get('/api/category');
      final productRes = await ApiService().get('/api/product/new?page=2&store_id=1');

      // Access the data inside Response.data
      final bannerList = bannerRes.data['data'] as List;
      final categoryList = categoryRes.data['data'] as List;
      final productList = productRes.data['data'] as List;

      // Map JSON to models
      banners.value =
          bannerList.map((e) => BannerModel.fromJson(e)).toList();
      categories.value =
          categoryList.map((e) => CategoryModel.fromJson(e)).toList();
      products.value =
          productList.map((e) => ProductModel.fromJson(e)).toList();

      print('Banners: ${banners.length}');
      print('Categories: ${categories.length}');
      print('Products: ${products.length}');
    } catch (e) {
      print("ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
