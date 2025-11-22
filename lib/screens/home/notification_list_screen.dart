import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grocery_app/controllers/notification_controller.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:shimmer/shimmer.dart';

class NotificationListScreen extends StatelessWidget {
  NotificationListScreen({super.key});

  final NotificationController controller = Get.put(NotificationController());

  final RxInt visibleCount = 20.obs; // show 10 notifications initially
  final RxBool isLoadingMore = false.obs;

  void _loadMore() async {
    isLoadingMore.value = true;

    await Future.delayed(const Duration(seconds: 1));

    visibleCount.value =
        (visibleCount.value + 10).clamp(0, controller.notifications.length);

    isLoadingMore.value = false;
  }

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
          // shimmer loading
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                width: double.infinity,
                                height: 16,
                                color: Colors.white),
                            const SizedBox(height: 8),
                            Container(
                                width: 150, height: 14, color: Colors.white),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(width: 40, height: 14, color: Colors.white),
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
                  Icon(Icons.notifications_off,
                      size: 80, color: Colors.grey[400]),
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

        final list = controller.notifications.take(visibleCount.value).toList();

        return ListView.separated(
          itemCount: list.length + 1, // +1 for load more button
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, index) {
            if (index == list.length) {
              // Load More Button or Loading Indicator
              if (visibleCount.value >= controller.notifications.length) {
                return const SizedBox.shrink(); // no more
              }
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Obx(() {
                    if (isLoadingMore.value) {
                      return const Padding(
                        padding: EdgeInsets.all(5.0),
                        child: CircularProgressIndicator( color: AppColors.primaryColor),
                      );
                    }
                    return ElevatedButton(
                      onPressed: _loadMore,
                      child: const Text(
                        "Load More",
                        style: TextStyle(color: AppColors.primaryColor),
                      ),
                    );
                  }),
                ),
              );
            }

            final item = list[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    item.isRead ? Colors.grey[300] : AppColors.primaryColor,
                child: const Icon(Icons.notifications, color: Colors.white),
              ),
              title: Text(
                item.message,
                style: TextStyle(
                  fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Text(item.type),
              trailing: Text(
                "${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              onTap: () async {
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
