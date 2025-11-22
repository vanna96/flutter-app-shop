import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grocery_app/models/notification_model.dart';
import 'package:grocery_app/services/api_service.dart';

class NotificationController extends GetxController {
  var isLoading = true.obs;
  final box = GetStorage();


  RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  @override
  void onInit() {
    fetchInitData();
    super.onInit();
  }

  Future<void> fetchInitData() async {
    try {
      isLoading.value = true;
      final storedData = box.read("user");

      if (storedData == null || storedData['token'] == null) {
        print("No stored token. Skipping fetchInitData.");
        isLoading.value = false;
        return;
      }

      final notificationRes = await ApiService().dio.get(
        "/api/notifications",
        options: Options(
          headers: {"Authorization": "Bearer ${storedData['token']}"},
          validateStatus: (status) => status! < 500,
        ),
      );
      final notificationList = notificationRes.data['data'] as List;

      // Map JSON to models
      notifications.value =
          notificationList.map((e) => NotificationModel.fromJson(e)).toList();
      print(notificationList);
    } catch (e) {
      print("ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final storedData = box.read("user");

      final res = await ApiService().dio.get(
        "/api/notification/$notificationId/read",
        options: Options(
          headers: {"Authorization": "Bearer ${storedData['token']}"},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        // Update local notification
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final old = notifications[index];
          notifications[index] = NotificationModel(
            id: old.id,
            message: old.message,
            type: old.type,
            readAt: DateTime.now(), // mark as read
            createdAt: old.createdAt,
          );
          notifications.refresh(); // Update UI
        }
        return true;
      } else {
        print("Failed to mark as read: ${res.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error marking notification as read: $e");
      return false;
    }
  }

}
