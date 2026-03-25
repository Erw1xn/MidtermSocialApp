import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_bot_screen.dart';
import '../widgets/post_card.dart';
import '../models/post_model.dart';
import '../widgets/story_item.dart';
import 'search_screen.dart';
import 'marketplace_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(_auth.currentUser?.uid).snapshots(),
      builder: (context, snapshot) {
        String userImageUrl = 'https://www.w3schools.com/howto/img_avatar.png';
        String userRealName = 'User'; // Kinuha ang real name para sa comments

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          userImageUrl = data['profilePicUrl'] ?? userImageUrl;
          userRealName = data['name'] ?? userRealName;
        }

        // Listahan ng mga pages, ipinapasa ang user details sa HomeFeedView
        final List<Widget> _pages = [
          _HomeFeedView(currentUserImageUrl: userImageUrl, currentUserName: userRealName),
          const SearchScreen(),
          const NotificationsScreen(),
          const ProfileScreen(),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex > 2 ? _currentIndex - 1 : _currentIndex,
            children: _pages,
          ),
          floatingActionButton: Container(
            height: 65,
            width: 65,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF1877F2), Color(0xFF833AB4), Color(0xFFF77737)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreatePostScreen()),
                );
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 35, color: Colors.white),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index != 2) {
                setState(() => _currentIndex = index);
              }
            },
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.black,
            backgroundColor: Colors.white,
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
              const BottomNavigationBarItem(icon: Icon(Icons.add, color: Colors.transparent), label: ''),
              const BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Notifications'),
              BottomNavigationBarItem(
                icon: CircleAvatar(
                  radius: 12,
                  backgroundImage: NetworkImage(userImageUrl),
                ),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeFeedView extends StatefulWidget {
  final String currentUserImageUrl;
  final String currentUserName;

  const _HomeFeedView({
    required this.currentUserImageUrl,
    required this.currentUserName,
  });

  @override
  State<_HomeFeedView> createState() => _HomeFeedViewState();
}

class _HomeFeedViewState extends State<_HomeFeedView> {
  int _itemCount = 15;
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        setState(() {
          _itemCount += 10;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Post _generateRandomPost(int index) {
    final List<String> videoUrls = [
      "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
      "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4",
      "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
      "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
      "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
    ];

    final List<String> randomNames = ["TechGuru", "NatureLover", "TravelBug", "ChefDaily", "ArtInspo"];

    PostType contentType;
    if (index % 3 == 0) {
      contentType = PostType.news;
    } else if (index % 2 == 0) {
      contentType = PostType.video;
    } else {
      contentType = PostType.image;
    }

    String name = randomNames[index % randomNames.length];

    return Post(
      postId: "dummy_$index",
      userId: "random_$index",
      username: name,
      handle: "@${name.toLowerCase()}",
      profileUrl: "https://api.dicebear.com/7.x/avataaars/png?seed=$name$index",
      content: "This update is looking clean! Infinite scrolling is active. 🚀",
      mediaUrl: contentType == PostType.video
          ? videoUrls[index % videoUrls.length]
          : "https://picsum.photos/seed/$index/800/600",
      type: contentType,
      likes: "${(index + 1) * 10}",
      comments: "${index + 1}",
      newsTitle: contentType == PostType.news ? "The Future of FaceTagram" : null,
      newsSubtext: contentType == PostType.news ? "How we integrated Facebook and Instagram UIs." : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0.5,
        title: Row(
          children: [
            Image.asset('assets/images/splash_logo.png', height: 50),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF1877F2), Color(0xFF833AB4), Color(0xFFC13584), Color(0xFFF77737)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds),
              child: const Text(
                'FaceTagram',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MarketplaceScreen())),
            icon: const Icon(Icons.storefront_outlined, color: Colors.black, size: 28),
          ),
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MessagesScreen())),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Image.asset('assets/images/messenger_logo.png', height: 35, width: 50),
            ),
          ),
          IconButton(
            onPressed: () {
              _auth.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
            icon: const Icon(Icons.logout, color: Colors.black, size: 28),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: SizedBox(
          height: 60, width: 60,
          child: FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatBotScreen())),
            backgroundColor: Colors.white,
            elevation: 4,
            shape: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/images/chatbot_icon.png', fit: BoxFit.contain),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('posts').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          List<Post> allPostsToShow = [];

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            allPostsToShow = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Post(
                postId: doc.id,
                userId: data['userId'] ?? '',
                username: data['username'] ?? 'Anonymous',
                handle: "@${(data['username'] ?? 'user').toString().toLowerCase().replaceAll(' ', '')}",
                profileUrl: data['profileUrl'] ?? 'https://www.w3schools.com/howto/img_avatar.png',
                content: data['content'] ?? '',
                mediaUrl: data['mediaUrl'],
                type: PostType.values[data['type'] ?? 0],
                likes: data['likesCount']?.toString() ?? "0",
                comments: "0",
              );
            }).toList();
          }

          for (int i = 0; i < 10; i++) {
            allPostsToShow.add(_generateRandomPost(i));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').snapshots(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

              final allUsers = userSnapshot.data!.docs;
              final myUid = _auth.currentUser?.uid;

              return ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                itemCount: allPostsToShow.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _StoriesBar(allUsers: allUsers, currentUid: myUid);
                  }

                  final post = allPostsToShow[index - 1];

                  // NGAYON: Ipinapasa na ang tunay na profile picture at name
                  return PostCard(
                    currentUserName: widget.currentUserName,
                    currentUserProfilePic: widget.currentUserImageUrl,
                    post: post,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _StoriesBar extends StatelessWidget {
  final List<QueryDocumentSnapshot> allUsers;
  final String? currentUid;

  const _StoriesBar({required this.allUsers, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    QueryDocumentSnapshot? myDoc;
    List<QueryDocumentSnapshot> otherUsers = [];

    for (var doc in allUsers) {
      if (doc.id == currentUid) {
        myDoc = doc;
      } else {
        otherUsers.add(doc);
      }
    }

    const String defaultImg = 'https://www.w3schools.com/howto/img_avatar.png';

    return Container(
      color: Colors.white,
      height: 115,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (myDoc != null)
            StoryItem(
              name: "Your Story",
              imageUrl: (myDoc.data() as Map<String, dynamic>)['profilePicUrl'] ?? defaultImg,
              targetUserId: currentUid,
            ),
          ...otherUsers.map((userDoc) {
            final data = userDoc.data() as Map<String, dynamic>;
            return StoryItem(
              name: data['name'] ?? 'User',
              imageUrl: data['profilePicUrl'] ?? defaultImg,
              targetUserId: userDoc.id,
            );
          }).toList(),
        ],
      ),
    );
  }
}