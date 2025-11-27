import 'package:get/get.dart';
import 'package:demo_app/models/category_model.dart';
import 'package:demo_app/services/api_service.dart';

class CategoryController extends GetxController {
  var isLoading = true.obs;

  RxList<CategoryModel> categories = <CategoryModel>[].obs;

  @override
  void onInit() {
    fetchInitData();
    super.onInit();
  }

  Future<void> fetchInitData() async {
    try {
      isLoading.value = true;

      final categoryRes = await ApiService().get('/api/category');

      // Access the data inside Response.data
      final categoryList = categoryRes.data['data'] as List;

      // Map JSON to models
      categories.value =
          categoryList.map((e) => CategoryModel.fromJson(e)).toList();

    } catch (e) {
      print("ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
