import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grocery_app/controllers/notification_controller.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:shimmer/shimmer.dart';

class NotificationListScreen extends StatelessWidget {
  NotificationListScreen({super.key});

  final NotificationController controller = Get.put(NotificationController());

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Circle avatar placeholder
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text placeholder
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 150,
                              height: 14,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Time placeholder
                      Container(
                        width: 40,
                        height: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You don\'t have any notifications at the moment.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: controller.notifications.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final item = controller.notifications[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                item.isRead ? Colors.grey[300] : AppColors.primaryColor,
                child: const Icon(Icons.notifications, color: Colors.white),
              ),
              title: Text(
                item.message,
                style: TextStyle(
                  fontWeight:
                  item.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Text(item.type),
              trailing: Text(
                "${item.createdAt.hour}:${item.createdAt.minute}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              onTap: () async {
                // Optionally mark notification as read
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(content: Text('Tapped on: ${item.message}')),
                // );
                if (!item.isRead) {
                  await controller.markAsRead(item.id);
                }
              },
            );
          },
        );
      }),
    );
  }
}
