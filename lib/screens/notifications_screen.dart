import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  // Removed const
  NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> notifications = [
      "Your wishlist item is now available!",
      "New message from John Doe",
      "Swap completed for item: Bike"
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.notifications),
            title: Text(notifications[index]),
          );
        },
      ),
    );
  }
}
