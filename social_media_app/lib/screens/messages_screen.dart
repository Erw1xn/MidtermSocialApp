import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends StatefulWidget {
  // sharedMediaUrl: Dito natatanggap ang link ng image/video galing sa PostCard 'Send' button
  final String? sharedMediaUrl;
  const MessagesScreen({super.key, this.sharedMediaUrl});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  // Kinukuha ang kasalukuyang User ID para sa filtering at room identification
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final String defaultImg = 'https://www.w3schools.com/howto/img_avatar.png';

  // Function para sa paghahanap ng user sa inbox gamit ang SearchDelegate
  void _showSearch(BuildContext context, List<DocumentSnapshot> users) {
    showSearch(
      context: context,
      delegate: MessageSearchDelegate(allUsers: users, defaultImg: defaultImg, currentUserId: currentUserId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chats',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Real-time listener para sa lahat ng registered users sa app
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No users found"));

          // Sinasala ang listahan para hindi lumabas ang sarili mong pangalan sa chat list
          final allUsers = snapshot.data!.docs.where((doc) => doc.id != currentUserId).toList();

          return Column(
            children: [
              // Search Bar UI: Kapag clinick, magbubukas ang search interface
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GestureDetector(
                  onTap: () => _showSearch(context, allUsers),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey, size: 20),
                        SizedBox(width: 10),
                        Text("Search", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 10),
                    // Horizontal list ng mga "Active Now" users
                    _buildActiveNowSection(allUsers),
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Divider(height: 1, thickness: 0.1, color: Colors.grey),
                    ),
                    // Pagbuo ng listahan ng mga chat tiles para sa bawat user
                    ...allUsers.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildChatItem(
                        context,
                        data['name'] ?? 'User',
                        data['profilePicUrl'] ?? defaultImg,
                        doc.id,
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget function para sa horizontal list ng mga contacts
  Widget _buildActiveNowSection(List<DocumentSnapshot> users) {
    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final data = users[index].data() as Map<String, dynamic>;
          final String name = data['name'] ?? 'User';
          final String img = data['profilePicUrl'] ?? defaultImg;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(name: name, profileImg: img, receiverId: users[index].id))),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(radius: 30, backgroundImage: NetworkImage(img)),
                      // Green dot indicator para sa "Online" status
                      Positioned(bottom: 5, right: 5, child: Container(height: 14, width: 14, decoration: BoxDecoration(color: const Color(0xFF44B700), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(name.split(' ')[0], style: const TextStyle(fontSize: 13, color: Colors.black87))
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget function para sa bawat row ng chat sa inbox
  Widget _buildChatItem(BuildContext context, String name, String img, String receiverId) {
    // ROOM ID LOGIC: Pagsasama ng dalawang User IDs nang naka-alphabetical order para sa unique chat room
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String roomId = ids.join("_");

    return StreamBuilder<DocumentSnapshot>(
      // Binabasa ang 'lastMessage' at 'lastTime' para ipakita sa preview ng Inbox
      stream: FirebaseFirestore.instance.collection('chats').doc(roomId).snapshots(),
      builder: (context, snapshot) {
        String lastMsg = "Tap to chat";
        String time = "Now";

        if (snapshot.hasData && snapshot.data!.exists) {
          var chatData = snapshot.data!.data() as Map<String, dynamic>;
          lastMsg = chatData['lastMessage'] ?? "Tap to chat";
          if (chatData['lastTime'] != null) {
            DateTime dt = (chatData['lastTime'] as Timestamp).toDate();
            time = "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
          }
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          onTap: () {
            // Pag-navigate sa detalye ng chat; Ipinapasa ang sharedMediaUrl dito
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  name: name,
                  profileImg: img,
                  receiverId: receiverId,
                  sharedMediaUrl: widget.sharedMediaUrl, // Ang URL na galing sa Newsfeed
                ),
              ),
            );
          },
          leading: CircleAvatar(radius: 30, backgroundImage: NetworkImage(img)),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
          subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        );
      },
    );
  }
}

// Delegate class para sa Search functionality ng mga users sa chat list
class MessageSearchDelegate extends SearchDelegate {
  final List<DocumentSnapshot> allUsers;
  final String defaultImg;
  final String currentUserId;
  MessageSearchDelegate({required this.allUsers, required this.defaultImg, required this.currentUserId});

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();
  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  // Logic para sa pagpapakita ng filtered users habang nag-ta-type sa search bar
  Widget _buildSearchResults() {
    final results = allUsers.where((doc) => (doc['name'] ?? '').toString().toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final data = results[index].data() as Map<String, dynamic>;
        return ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(data['profilePicUrl'] ?? defaultImg)),
          title: Text(data['name'] ?? 'User'),
          onTap: () {
            close(context, null);
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => ChatDetailScreen(name: data['name'], profileImg: data['profilePicUrl'], receiverId: results[index].id)));
          },
        );
      },
    );
  }
}