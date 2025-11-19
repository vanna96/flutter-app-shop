import 'package:get/get.dart';
import 'package:grocery_app/models/store_model.dart';
import 'package:grocery_app/services/api_service.dart';

class StoreController extends GetxController {
  var isLoading = true.obs;

  RxList<StoreModel> stores = <StoreModel>[].obs;

  @override
  void onInit() {
    fetchInitData();
    super.onInit();
  }

  Future<void> fetchInitData() async {
    try {
      isLoading.value = true;

      final storeRes = await ApiService().get('/api/store');


      // Access the data inside Response.data
      final storesList = storeRes.data['data'] as List;

      // Map JSON to models
      stores.value =  storesList.map((e) => StoreModel.fromJson(e)).toList();

    } catch (e) {
      print("ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
