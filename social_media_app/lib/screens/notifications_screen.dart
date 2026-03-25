import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> deleteNotification(String docId) async {
    await FirebaseFirestore.instance.collection('notifications').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 25, 20, 15),
          child: Text(
            'Notifications',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // FILTER: Ipakita lang ang notifications kung saan ang receiver ay IKAW
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('receiverId', isEqualTo: currentUserId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                // IMPORTANT: Kung may error dito, i-click ang link sa VS Code Debug Console
                return const Center(child: Text("Error loading data. Check console for Index link."));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text("No notifications yet."));
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final docId = docs[index].id;
                  final data = docs[index].data() as Map<String, dynamic>;

                  return Dismissible(
                    key: Key(docId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) => deleteNotification(docId),
                    child: _buildNotificationItem(
                      username: data['username'] ?? 'User',
                      imageUrl: data['imageUrl'] ?? '',
                      action: data['action'] ?? '',
                      time: _formatTimestamp(data['timestamp']),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem({
    required String username,
    required String imageUrl,
    required String action,
    required String time,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
        child: imageUrl.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 15),
          children: [
            TextSpan(text: username, style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: ' $action '),
            TextSpan(text: time, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime date = timestamp.toDate();
    Duration diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }
}