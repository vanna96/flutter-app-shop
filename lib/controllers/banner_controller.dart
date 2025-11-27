import 'package:get/get.dart';
import 'package:demo_app/models/banner_model.dart';
import 'package:demo_app/services/api_service.dart';

class BannerController extends GetxController {
  var isLoading = true.obs;

  RxList<BannerModel> banners = <BannerModel>[].obs;

  @override
  void onInit() {
    fetchInitData();
    super.onInit();
  }

  Future<void> fetchInitData() async {
    try {
      isLoading.value = true;

      final bannerRes = await ApiService().get('/api/slider');

      // Access the data inside Response.data
      final bannerList = bannerRes.data['data'] as List;

      // Map JSON to models
      banners.value =
          bannerList.map((e) => BannerModel.fromJson(e)).toList();

    } catch (e) {
      print("ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
