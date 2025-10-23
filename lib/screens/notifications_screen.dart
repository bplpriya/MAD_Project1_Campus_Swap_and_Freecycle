// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatelessWidget {
  NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;
              final message = data['message'] ?? '';
              final timestamp = data['timestamp'] as Timestamp?;

              String timeString = '';
              if (timestamp != null) {
                final date = timestamp.toDate();
                timeString = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
              }

              return ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(message),
                subtitle: Text(timeString),
              );
            },
          );
        },
      ),
    );
  }
}
