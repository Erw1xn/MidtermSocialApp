import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_media_app/screens/messages_screen.dart';
import '../models/post_model.dart';
import 'video_post_player.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final String currentUserName;
  final String currentUserProfilePic;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserName,
    required this.currentUserProfilePic,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isLiked = false;
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    var doc = await _firestore
        .collection('posts')
        .doc(widget.post.postId)
        .collection('likes')
        .doc(currentUser.uid)
        .get();

    if (mounted) {
      setState(() {
        _isLiked = doc.exists;
      });
    }
  }

  Future<void> _handleLikeToggle() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final postRef = _firestore.collection('posts').doc(widget.post.postId);

    setState(() {
      _isLiked = !_isLiked;
    });

    try {
      if (_isLiked) {
        await postRef.collection('likes').doc(currentUser.uid).set({
          'likedAt': FieldValue.serverTimestamp(),
          'username': widget.currentUserName,
          'profilePic': widget.currentUserProfilePic,
        });

        await postRef.update({'likesCount': FieldValue.increment(1)});

        if (widget.post.userId != currentUser.uid) {
          await _firestore.collection('notifications').add({
            'action': 'liked your post ❤️',
            'imageUrl': widget.currentUserProfilePic,
            'receiverId': widget.post.userId,
            'senderId': currentUser.uid,
            'timestamp': FieldValue.serverTimestamp(),
            'username': widget.currentUserName,
          });
        }
      } else {
        await postRef.collection('likes').doc(currentUser.uid).delete();
        await postRef.update({'likesCount': FieldValue.increment(-1)});
      }
    } catch (e) {
      debugPrint("Like Error: $e");
    }
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4, width: 40,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 20),
              const Text("Share Post", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MessagesScreen(
                              sharedMediaUrl: widget.post.mediaUrl,
                            ),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        child: const Icon(Icons.send, color: Colors.purple, size: 35),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text("Send to Friends", style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addComment() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || _commentController.text.isEmpty) return;

    String commentText = _commentController.text;
    _commentController.clear();

    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final realName = userDoc.data()?['name'] ?? 'User';
      final realProfilePic = userDoc.data()?['profilePicUrl'] ?? 'https://www.w3schools.com/howto/img_avatar.png';

      await _firestore.collection('posts').doc(widget.post.postId).collection('comments').add({
        'user': realName,
        'comment': commentText,
        'pic': realProfilePic,
        'userId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (widget.post.userId != currentUser.uid) {
        await _firestore.collection('notifications').add({
          'action': 'commented: "$commentText" 💬',
          'imageUrl': realProfilePic,
          'receiverId': widget.post.userId,
          'senderId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'username': realName,
        });
      }
    } catch (e) {
      debugPrint("Comment Error: $e");
    }
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
          children: [
            Container(margin: const EdgeInsets.symmetric(vertical: 10), height: 5, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('posts').doc(widget.post.postId).collection('comments').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var docs = snapshot.data!.docs;
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(data['pic'] ?? 'https://www.w3schools.com/howto/img_avatar.png'),
                        ),
                        title: Text(data['user'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(data['comment'] ?? ''),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 10, left: 15, right: 15, top: 10),
              child: Row(
                children: [
                  // INAYOS DITO: Pinalitan ng foregroundImage para siguradong pumatong ang picture ng user
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[200],
                    foregroundImage: widget.currentUserProfilePic.isNotEmpty
                        ? NetworkImage(widget.currentUserProfilePic)
                        : null,
                    child: const Icon(Icons.person, size: 18, color: Colors.grey),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _commentController, decoration: const InputDecoration(hintText: "Add a comment...", border: InputBorder.none))),
                  TextButton(onPressed: _addComment, child: const Text("Post", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(widget.post.profileUrl)),
            title: Text(widget.post.username, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(widget.post.type == PostType.news ? "Page name • Sponsored" : widget.post.handle),
          ),

          if (widget.post.type == PostType.video) ...[
            if (widget.post.mediaUrl != null) VideoPostPlayer(videoUrl: widget.post.mediaUrl!),
          ] else if (widget.post.type == PostType.image) ...[
            if (widget.post.mediaUrl != null)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)), body: Center(child: InteractiveViewer(child: Image.network(widget.post.mediaUrl!, fit: BoxFit.contain)))))),
                child: Image.network(widget.post.mediaUrl!, fit: BoxFit.cover, width: double.infinity),
              ),
          ] else ...[
            _buildNewsBox(),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : Colors.black, size: 28),
                  onPressed: _handleLikeToggle,
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 26),
                  onPressed: () => _showComments(context),
                ),
                IconButton(
                  icon: const Icon(Icons.send_outlined, size: 26),
                  onPressed: () => _showShareOptions(context),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(widget.post.content, style: const TextStyle(fontSize: 14)),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                StreamBuilder<DocumentSnapshot>(
                    stream: _firestore.collection('posts').doc(widget.post.postId).snapshots(),
                    builder: (context, snapshot) {
                      int likes = 0;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        var data = snapshot.data!.data() as Map<String, dynamic>;
                        likes = data['likesCount'] ?? 0;
                      }
                      return Text("$likes likes", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13));
                    }
                ),
                const SizedBox(width: 15),
                StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('posts').doc(widget.post.postId).collection('comments').snapshots(),
                    builder: (context, snapshot) {
                      int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return Text("View all $count comments", style: const TextStyle(color: Colors.grey, fontSize: 13));
                    }
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildNewsBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.post.mediaUrl != null)
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: Image.network(widget.post.mediaUrl!, fit: BoxFit.cover)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("NEWS LINK", style: TextStyle(color: Colors.grey, fontSize: 11)),
                Text(widget.post.newsTitle ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(widget.post.newsSubtext ?? "", maxLines: 2, style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}