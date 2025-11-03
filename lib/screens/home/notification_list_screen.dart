import 'package:flutter/material.dart';

import '../../styles/colors.dart';

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

  // Example dummy notification data
  final List<Map<String, dynamic>> notifications = const [
    {
      'title': 'New Order Received',
      'message': 'You have received a new order #1023.',
      'time': '2 min ago',
      'isRead': false,
    },
    {
      'title': 'System Update',
      'message': 'System maintenance scheduled for tonight.',
      'time': '1 hour ago',
      'isRead': true,
    },
    {
      'title': 'Promotion Alert',
      'message': 'Get 20% off on your next purchase!',
      'time': '3 hours ago',
      'isRead': false,
    },
    {
      'title': 'Payment Successful',
      'message': 'Your payment of \$59.00 has been processed.',
      'time': 'Yesterday',
      'isRead': true,
    },
  ];

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
      body: RefreshIndicator(
        onRefresh: () async {
          // Simulate network refresh delay
          await Future.delayed(const Duration(seconds: 1));
        },
        child: notifications.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 80,
                        color: Colors.grey[400],
                      ),
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
              )
            : ListView.separated(
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          item['isRead'] ? Colors.grey[300] : AppColors.primaryColor,
                      child:
                          const Icon(Icons.notifications, color: Colors.white),
                    ),
                    title: Text(
                      item['title'],
                      style: TextStyle(
                        fontWeight: item['isRead']
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(item['message']),
                    trailing: Text(
                      item['time'],
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onTap: () {
                      // Handle notification tap
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tapped on: ${item['title']}')),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
