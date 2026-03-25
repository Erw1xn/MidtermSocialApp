import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/post_card.dart';
import '../models/post_model.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isPostsTab = true;

  String? get targetUserId => widget.userId ?? _auth.currentUser?.uid;
  bool get isMe => targetUserId == _auth.currentUser?.uid;

  Future<void> _toggleFollow(bool isFollowing, Map<String, dynamic> targetUserData) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || targetUserId == null || isMe) return;

    final myDocRef = _firestore.collection('users').doc(currentUser.uid);
    final theirDocRef = _firestore.collection('users').doc(targetUserId!);

    try {
      if (isFollowing) {
        await myDocRef.update({'following': FieldValue.arrayRemove([targetUserId])});
        await theirDocRef.update({'followers': FieldValue.arrayRemove([currentUser.uid])});
      } else {
        await myDocRef.update({'following': FieldValue.arrayUnion([targetUserId])});
        await theirDocRef.update({'followers': FieldValue.arrayUnion([currentUser.uid])});

        await _firestore.collection('notifications').add({
          'action': 'started following you 👤',
          'receiverId': targetUserId,
          'senderId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'username': 'Someone',
        });
      }
    } catch (e) {
      debugPrint("Follow Toggle Error: $e");
    }
  }

  Future<void> _updateProfile(Map<String, dynamic> data) async {
    if (targetUserId == null) return;
    try {
      await _firestore.collection('users').doc(targetUserId).set(
        {...data, 'uid': targetUserId, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
      }
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (targetUserId == null) return const Scaffold(body: Center(child: Text("User not logged in")));

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(targetUserId!).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Scaffold(body: Center(child: Text("Error loading user data")));
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        String name = userData['name'] ?? 'User';
        String handle = userData['headline'] ?? 'username';
        String bio = userData['bio'] ?? 'No bio available';
        String cover = userData['coverPhotoUrl'] ?? 'https://picsum.photos/800/600';
        String profile = userData['profilePicUrl'] ?? 'https://www.w3schools.com/howto/img_avatar.png';

        List followersList = userData['followers'] ?? [];
        bool amIFollowing = followersList.contains(_auth.currentUser?.uid);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(isMe ? 'My Profile' : name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildHeader(cover, profile),
                    const SizedBox(height: 65),
                    _buildProfileInfo(name, handle, bio),
                    _buildStatSection(userData),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(flex: 1, child: _buildFollowButton(amIFollowing, userData)),
                          const SizedBox(width: 10),
                          Expanded(flex: 1, child: _buildEditButton(userData)),
                        ],
                      ),
                    ),
                    _buildTabs(),
                  ],
                ),
              ),
              isPostsTab
                  ? _buildSliverPostList(userData)
                  : SliverToBoxAdapter(child: _buildAboutSection(userData)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatSection(Map<String, dynamic> userData) {
    List followers = userData['followers'] ?? [];
    List following = userData['following'] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('posts').where('userId', isEqualTo: targetUserId).snapshots(),
            builder: (context, snapshot) {
              int postCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return _buildStatItem("Posts", postCount.toString());
            },
          ),
          _buildStatItem("Followers", followers.length.toString()),
          _buildStatItem("Following", following.length.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w400)),
      ],
    );
  }

  Widget _buildFollowButton(bool isFollowing, Map<String, dynamic> userData) {
    String buttonText = isMe ? 'You' : (isFollowing ? 'Following' : 'Follow');
    Color buttonColor = isMe ? Colors.grey.shade300 : (isFollowing ? Colors.grey.shade200 : const Color(0xFF1877F2));
    Color textColor = isFollowing || isMe ? Colors.black : Colors.white;

    return ElevatedButton(
      onPressed: isMe ? null : () => _toggleFollow(isFollowing, userData),
      style: ElevatedButton.styleFrom(backgroundColor: buttonColor, foregroundColor: textColor, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildEditButton(Map<String, dynamic> userData) {
    return OutlinedButton(
        onPressed: isMe ? () => _showEditProfileDialog(userData) : null,
        style: OutlinedButton.styleFrom(side: BorderSide(color: isMe ? Colors.grey[300]! : Colors.grey.shade100), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 12)),
        child: Text('Edit Profile', style: TextStyle(color: isMe ? Colors.black : Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 13))
    );
  }

  Widget _buildSliverPostList(Map<String, dynamic> userData) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('posts').where('userId', isEqualTo: targetUserId).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(60), child: Center(child: Text("No posts found."))));
        final postDocs = snapshot.data!.docs;
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final data = postDocs[index].data() as Map<String, dynamic>;

            // IN-UPDATE ANG MAPPING PARA SA POST ID AT LIKES COUNT
            final post = Post(
                postId: postDocs[index].id, // Kinuha ang Document ID
                userId: data['userId'] ?? '',
                username: userData['name'] ?? 'User',
                handle: "@${userData['headline'] ?? 'user'}",
                profileUrl: userData['profilePicUrl'] ?? 'https://www.w3schools.com/howto/img_avatar.png',
                content: data['content'] ?? '',
                mediaUrl: data['mediaUrl'],
                type: PostType.values[data['type'] ?? 0],
                likes: data['likesCount']?.toString() ?? "0", // String conversion para sa model
                comments: "0"
            );
            return PostCard(currentUserName: userData['name'] ?? "User", currentUserProfilePic: userData['profilePicUrl'] ?? 'https://www.w3schools.com/howto/img_avatar.png', post: post);
          }, childCount: postDocs.length),
        );
      },
    );
  }

  Widget _buildHeader(String cover, String profile) {
    return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
      SizedBox(height: 180, width: double.infinity, child: Image.network(cover, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey[300]))),
      Positioned(bottom: -60, child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4.0)), child: CircleAvatar(radius: 60, backgroundImage: NetworkImage(profile))))
    ]);
  }

  Widget _buildProfileInfo(String n, String h, String b) {
    return Column(children: [
      Text(n, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      Text("@$h", style: const TextStyle(fontSize: 15, color: Colors.blue, fontWeight: FontWeight.w500)),
      const SizedBox(height: 10),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Text(b, style: const TextStyle(fontSize: 14, color: Colors.black87), textAlign: TextAlign.center)),
    ]);
  }

  Widget _buildTabs() {
    return Column(children: [
      const SizedBox(height: 10),
      const Divider(height: 1),
      Row(children: [
        _tabItem("Posts", isPostsTab, () => setState(() => isPostsTab = true)),
        _tabItem("About", !isPostsTab, () => setState(() => isPostsTab = false)),
      ]),
      const Divider(height: 1),
    ]);
  }

  Widget _tabItem(String title, bool active, VoidCallback onTap) {
    return Expanded(child: InkWell(onTap: onTap, child: Column(children: [const SizedBox(height: 12), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: active ? Colors.black : Colors.grey)), const SizedBox(height: 12), if (active) Container(height: 2, color: Colors.black)])));
  }

  Widget _buildAboutSection(Map<String, dynamic> data) {
    return Padding(padding: const EdgeInsets.all(16.0), child: Column(children: [_aboutCard(Icons.person, "Bio", data['bio'] ?? 'N/A'), _aboutCard(Icons.school, "Education", "Global Reciprocal Colleges"), _aboutCard(Icons.location_on, "Location", "Malabon City, Philippines")]));
  }

  Widget _aboutCard(IconData icon, String title, String sub) {
    return ListTile(leading: Icon(icon, color: Colors.black54), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(sub));
  }

  void _showEditProfileDialog(Map<String, dynamic> data) {
    TextEditingController nameCtrl = TextEditingController(text: data['name'] ?? '');
    TextEditingController headlineCtrl = TextEditingController(text: data['headline'] ?? '');
    TextEditingController bioCtrl = TextEditingController(text: data['bio'] ?? '');
    TextEditingController coverCtrl = TextEditingController(text: data['coverPhotoUrl'] ?? '');
    TextEditingController profilePicCtrl = TextEditingController(text: data['profilePicUrl'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _buildStyledField(nameCtrl, "Full Name", Icons.person),
            _buildStyledField(headlineCtrl, "Username", Icons.alternate_email),
            _buildStyledField(bioCtrl, "Bio", Icons.work),
            _buildStyledField(coverCtrl, "Cover URL", Icons.image),
            _buildStyledField(profilePicCtrl, "Profile URL", Icons.face),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _updateProfile({'name': nameCtrl.text, 'headline': headlineCtrl.text, 'bio': bioCtrl.text, 'coverPhotoUrl': coverCtrl.text, 'profilePicUrl': profilePicCtrl.text});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledField(TextEditingController ctrl, String label, IconData icon) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: ctrl, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))));
  }
}