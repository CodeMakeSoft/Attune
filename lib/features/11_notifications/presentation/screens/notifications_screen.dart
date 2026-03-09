import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attune/core/models/user_model.dart';
import 'package:attune/core/models/notification_model.dart';
import 'package:attune/core/services/firestore_service.dart';
import 'package:attune/utils/app_colors.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  final User currentUser;
  const NotificationsScreen({super.key, required this.currentUser});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getUserNotifications(widget.currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar notificaciones."));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text("No tienes notificaciones", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          // Transformar y ordenar desde el dispositivo (para no requerir Index en Firebase)
          final rawDocs = snapshot.data!.docs;
          List<AppNotification> notifs = rawDocs.map((doc) {
            return AppNotification.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();
          
          notifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            itemCount: notifs.length,
            itemBuilder: (context, index) {
              final notif = notifs[index];
              return _buildNotificationCard(notif);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notif) {
    final dateFormat = DateFormat('dd MMM yyyy - HH:mm', 'es');
    
    IconData icon;
    Color iconColor;

    switch (notif.type) {
      case 'leave_request':
        icon = Icons.event_available;
        iconColor = AppColors.stateSuccess;
        break;
      case 'event':
        icon = Icons.campaign;
        iconColor = AppColors.accentSecondary;
        break;
      default:
        icon = Icons.notifications;
        iconColor = AppColors.accentPrimary;
    }

    return Container(
      color: notif.isRead ? Colors.transparent : AppColors.accentPrimary.withOpacity(0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          notif.title,
          style: TextStyle(
            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
            color: AppColors.contentPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notif.body,
              style: TextStyle(color: AppColors.contentSecondary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              dateFormat.format(notif.createdAt),
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        onTap: () {
          if (!notif.isRead) {
            _firestoreService.markNotificationAsRead(notif.id);
          }
        },
      ),
    );
  }
}
