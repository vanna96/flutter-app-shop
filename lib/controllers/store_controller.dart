import 'package:get/get.dart';
import 'package:demo_app/models/store_model.dart';
import 'package:demo_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreController extends GetxController {
  var isLoading = true.obs;

  // Stores list
  RxList<StoreModel> stores = <StoreModel>[].obs;

  // Selected store ID
  RxInt selectedLocationId = 0.obs;

  @override
  void onInit() {
    fetchInitData();
    super.onInit();
  }

  Future<void> fetchInitData() async {
    try {
      isLoading.value = true;

      // Load saved ID
      final prefs = await SharedPreferences.getInstance();
      int? savedId = prefs.getInt('store_id');

      // 1. Fetch stores from API
      final storeRes = await ApiService().get('/api/store');
      final storesList = storeRes.data['data'] as List;
      stores.value = storesList.map((e) => StoreModel.fromJson(e)).toList();

      // 2. If no saved ID → select first store automatically
      if (savedId == null || savedId == 0) {
        selectedLocationId.value = stores.first.id; // <-- default
        await prefs.setInt('store_id', selectedLocationId.value);
      } else {
        selectedLocationId.value = savedId; // load saved
      }

    } catch (e) {
      print("ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Call this when user changes location/store
  Future<void> updateSelectedStore(int id) async {
    selectedLocationId.value = id;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('store_id', id);
  }
}
