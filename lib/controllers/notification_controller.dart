import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grocery_app/data/mock_data.dart';
import 'package:grocery_app/models/notification_model.dart';
import 'package:grocery_app/services/mobile_api_repository.dart';

class NotificationController extends GetxController {
  var isLoading = true.obs;
  final box = GetStorage();
  final MobileApiRepository _mobileApiRepository = MobileApiRepository();

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
        notifications.clear();
        return;
      }

      final remoteNotifications = await _mobileApiRepository
          .fetchNotifications();
      remoteNotifications.sort((a, b) {
        if (a.readAt == null && b.readAt != null) return -1;
        if (a.readAt != null && b.readAt == null) return 1;
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        return bDate.compareTo(aDate);
      });

      MockDataRepository.updateNotifications(remoteNotifications);
      notifications.value = List<NotificationModel>.from(
        MockDataRepository.notifications,
      );
    } catch (e) {
      notifications.value = List<NotificationModel>.from(
        MockDataRepository.notifications,
      );
      print('ERROR: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      await _mobileApiRepository.markNotificationRead(notificationId);
      final index = notifications.indexWhere(
        (notification) => notification.id == notificationId,
      );
      if (index == -1) {
        return false;
      }

      final old = notifications[index];
      notifications[index] = NotificationModel(
        id: old.id,
        message: old.message,
        type: old.type,
        readAt: DateTime.now(),
        createdAt: old.createdAt,
      );
      notifications.sort((a, b) {
        if (a.readAt == null && b.readAt != null) return -1;
        if (a.readAt != null && b.readAt == null) return 1;
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        return bDate.compareTo(aDate);
      });
      notifications.refresh();
      MockDataRepository.updateNotifications(notifications);
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }
}
