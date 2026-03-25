import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatDetailScreen extends StatefulWidget {
  final String name;
  final String profileImg;
  final String receiverId;
  final String? sharedMediaUrl;

  const ChatDetailScreen({
    super.key,
    required this.name,
    required this.profileImg,
    required this.receiverId,
    this.sharedMediaUrl,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    // AUTOMATIC FORWARD LOGIC:
    // Kapag pumasok sa chat at may bitbit na sharedMediaUrl, kusa itong ise-send agad.
    if (widget.sharedMediaUrl != null && widget.sharedMediaUrl!.isNotEmpty) {
      _sendSharedPost(widget.sharedMediaUrl!);
    }
  }

  // Helper function para makuha ang format ng Room ID na pareho sa MessagesScreen
  String getChatRoomId() {
    List<String> ids = [currentUserId, widget.receiverId];
    ids.sort();
    return ids.join("_");
  }

  // FUNCTION PARA SA AUTO-SEND NG PINASANG MEDIA (IMAGE/VIDEO)
  void _sendSharedPost(String url) async {
    final roomId = getChatRoomId();

    // 1. Pag-add ng URL bilang bagong message sa 'messages' sub-collection
    await FirebaseFirestore.instance.collection('chats').doc(roomId).collection('messages').add({
      'senderId': currentUserId,
      'text': url, // Ang link ng post ang nagsisilbing message text
      'timestamp': FieldValue.serverTimestamp(),
      'isMedia': true, // Flag para malaman ng UI na image ito at hindi text
    });

    // 2. Update sa Main Chat Document para sa huling chat preview sa Inbox
    await FirebaseFirestore.instance.collection('chats').doc(roomId).set({
      'lastMessage': "Shared a post 🖼️",
      'lastTime': FieldValue.serverTimestamp(),
      'users': [currentUserId, widget.receiverId],
    }, SetOptions(merge: true));

    // 3. Pagpapadala ng Notification sa kabilang party (receiverId)
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    String myName = userDoc.data()?['name'] ?? 'User';
    String myProfilePic = userDoc.data()?['profilePicUrl'] ?? '';

    await FirebaseFirestore.instance.collection('notifications').add({
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
      'username': myName,
      'action': 'shared a post with you 🖼️',
      'imageUrl': myProfilePic,
      'timestamp': FieldValue.serverTimestamp(),
      'hasStory': false,
    });
  }

  // FUNCTION PARA SA PAGPAPADALA NG NORMAL NA TEXT MESSAGE
  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    String messageText = _controller.text.trim();
    _controller.clear();
    final roomId = getChatRoomId();

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    String myName = userDoc.data()?['name'] ?? 'User';
    String myProfilePic = userDoc.data()?['profilePicUrl'] ?? '';

    // Pag-save ng text message sa Firestore
    await FirebaseFirestore.instance.collection('chats').doc(roomId).collection('messages').add({
      'senderId': currentUserId,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Pag-update sa Inbox preview para ipakita ang huling text
    await FirebaseFirestore.instance.collection('chats').doc(roomId).set({
      'lastMessage': messageText,
      'lastTime': FieldValue.serverTimestamp(),
      'users': [currentUserId, widget.receiverId],
    }, SetOptions(merge: true));

    // Notification para sa bagong text chat
    await FirebaseFirestore.instance.collection('notifications').add({
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
      'username': myName,
      'action': 'sent you a message 💬',
      'imageUrl': myProfilePic,
      'timestamp': FieldValue.serverTimestamp(),
      'hasStory': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            CircleAvatar(radius: 18, backgroundImage: NetworkImage(widget.profileImg)),
            const SizedBox(width: 10),
            Text(widget.name, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Nakikinig sa lahat ng messages ng conversation, naka-sort by time (latest first)
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(getChatRoomId())
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true, // Nagsisimula ang scroll sa pinaka-ibaba
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    String time = "";
                    if (data['timestamp'] != null) {
                      DateTime date = (data['timestamp'] as Timestamp).toDate();
                      time = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                    }

                    return _buildMessageBubble(data['text'] ?? "", data['senderId'] == currentUserId, time);
                  },
                );
              },
            ),
          ),
          _buildInputBar(), // Bar para sa pag-type ng message
        ],
      ),
    );
  }

  // WIDGET PARA SA CHAT BUBBLES: Nade-detect kung Image o Text ang nilalaman
  Widget _buildMessageBubble(String text, bool isMe, String time) {
    final String cleanText = text.trim();

    // IMAGE DETECTION: Chine-check kung ang text ay isang image URL (galing sa storage o picsum)
    bool isImage = cleanText.startsWith('http') &&
        (cleanText.toLowerCase().contains('.jpg') ||
            cleanText.toLowerCase().contains('.png') ||
            cleanText.toLowerCase().contains('.jpeg') ||
            cleanText.toLowerCase().contains('.webp') ||
            cleanText.toLowerCase().contains('.gif') ||
            cleanText.contains('fna.fbcdn.net') ||
            cleanText.contains('picsum.photos') ||
            cleanText.contains('images.unsplash.com'));

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(top: 5),
            padding: isImage ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
            ),
            // KUNG IMAGE: Ipapakita gamit ang Image.network; KUNG TEXT: Gagamit ng Text widget
            child: isImage
                ? ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                cleanText,
                width: 250,
                height: 250,
                fit: BoxFit.cover,
                cacheWidth: 500,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(width: 250, height: 250, color: Colors.grey[100], child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                },
                errorBuilder: (context, error, stackTrace) => Padding(padding: const EdgeInsets.all(8.0), child: Text(cleanText, style: const TextStyle(fontSize: 12, color: Colors.red))),
              ),
            )
                : Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 16)),
          ),
        ),
        Padding(padding: const EdgeInsets.only(bottom: 8.0, top: 2), child: Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey))),
      ],
    );
  }

  // Input area sa ilalim ng chat screen
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[300]!, width: 0.5))),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(25)),
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(hintText: "Type a message...", border: InputBorder.none),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: _sendMessage),
        ],
      ),
    );
  }
} 