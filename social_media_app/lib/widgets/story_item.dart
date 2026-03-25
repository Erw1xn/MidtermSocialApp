import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryItem extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String? targetUserId; // UID of the story owner
  final bool isLive;

  const StoryItem({
    super.key,
    required this.name,
    required this.imageUrl,
    this.targetUserId,
    this.isLive = false,
  });

  void _showStory(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Story",
      pageBuilder: (context, anim1, anim2) {
        final currentUser = FirebaseAuth.instance.currentUser;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // 1. BACKGROUND
              SizedBox.expand(
                child: Image.network(
                  'https://picsum.photos/seed/${name.hashCode + 1}/1080/1920',
                  fit: BoxFit.cover,
                ),
              ),

              // 2. HEADER
              Positioned(
                top: 50,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    CircleAvatar(radius: 18, backgroundImage: NetworkImage(imageUrl)),
                    const SizedBox(width: 10),
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // 3. HEART BUTTON CONNECTED TO LIKES & NOTIFICATIONS
              Positioned(
                bottom: 40,
                right: 20,
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(targetUserId)
                      .collection('story_likes')
                      .doc(currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    bool isLiked = snapshot.hasData && snapshot.data!.exists;

                    return GestureDetector(
                      // Inside StoryItem -> onTap logic
                      onTap: () async {
                        if (currentUser == null || targetUserId == null) return;

                        // 1. References
                        final userDocRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
                        final notificationRef = FirebaseFirestore.instance.collection('notifications');
                        final likeRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(targetUserId)
                            .collection('story_likes')
                            .doc(currentUser.uid);

                        if (!isLiked) {
                          // 2. Fetch the current user's actual name from their Firestore document
                          final myProfile = await userDocRef.get();
                          final String myActualName = myProfile.data()?['name'] ?? "User";
                          final String myProfilePic = myProfile.data()?['profilePicUrl'] ?? imageUrl;

                          // 3. Save the Like
                          await likeRef.set({
                            'likedBy': currentUser.uid,
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                          // 4. Save the Notification with the actual name
                          await notificationRef.add({
                            'action': 'liked your story ❤️',
                            'hasStory': true,
                            'imageUrl': myProfilePic,
                            'receiverId': targetUserId,
                            'senderId': currentUser.uid,
                            'timestamp': FieldValue.serverTimestamp(),
                            'username': myActualName, // This will now show the real name (e.g., "Francine Noe")
                          });
                        } else {
                          // Remove the Like
                          await likeRef.delete();
                        }
                      },
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.white,
                        size: 35,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showStory(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isLive ? [Colors.red, Colors.orange] : [Colors.purple, Colors.red, Colors.orange],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: CircleAvatar(radius: 30, backgroundImage: NetworkImage(imageUrl)),
              ),
            ),
            const SizedBox(height: 5),
            Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}