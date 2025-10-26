// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatelessWidget {
  NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications 🔔')),
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
            padding: const EdgeInsets.all(8.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;
              final message = data['message'] ?? 'New Notification';
              final timestamp = data['timestamp'] as Timestamp?;

              String timeString = 'N/A';
              if (timestamp != null) {
                final date = timestamp.toDate();
                timeString =
                    '${date.month}/${date.day}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                elevation: 1,
                child: ListTile(
                  leading: const Icon(Icons.notifications_active, color: Colors.amber),
                  title: Text(
                    message, 
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(timeString, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_right),
                ),
              );
            },
          );
        },
      ),
    );
  }
}