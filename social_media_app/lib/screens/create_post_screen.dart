import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  // --- VARIABLES & CONTROLLERS ---
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  PostType _selectedType = PostType.image;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function para sa pag-upload ng post sa Firebase Firestore
  void _uploadPost() async {
    // 1. Validation: Siguraduhing may laman ang caption at URL bago mag-proceed
    if (_captionController.text.isEmpty || _urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    // I-set ang loading state sa true para ipakita ang progress indicator
    setState(() => _isLoading = true);

    try {
      // 2. Kunin ang user details (name at profile pic) mula sa 'users' collection sa Firestore
      final userDoc = await _firestore.collection('users').doc(_auth.currentUser?.uid).get();

      // 3. GUMAWA NG BAGONG DOCUMENT REFERENCE PARA MAKUHA ANG UNIQUE ID (POST ID)
      // Ito ang sikreto para gumana ang counting ng likes sa tamang post
      DocumentReference postRef = _firestore.collection('posts').doc();

      // 4. I-save ang bagong post data sa 'posts' collection gamit ang unique ID
      await postRef.set({
        'postId': postRef.id, // I-save ang sariling ID ng document
        'userId': _auth.currentUser?.uid,
        'username': userDoc['name'] ?? 'User',
        'profileUrl': userDoc['profilePicUrl'] ?? 'https://www.w3schools.com/howto/img_avatar.png',
        'content': _captionController.text,
        'mediaUrl': _urlController.text,
        'type': _selectedType.index,
        'likesCount': 0, // Ginawang INTEGER (0) sa halip na String ("0") para gumana ang math
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 5. Pagkatapos ma-upload, isara ang screen at bumalik sa previous page
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Magpakita ng error message kung pumalya ang upload
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      // Siguraduhing i-off ang loading state kahit mag-success o mag-error
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Create New Post",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Button para i-trigger ang _uploadPost function
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _uploadPost, // Disable button habang naglo-load
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Post", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- SECTION 1: CONTENT INPUT (Caption area) ---
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("What's on your mind?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  TextField(
                    controller: _captionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Write a caption...",
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),

            // --- SECTION 2: MEDIA OPTIONS (Type Selector and URL Input) ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTypeSelector(PostType.image, Icons.image_rounded, "Photo", const Color(0xFFE3F2FD)),
                      _buildTypeSelector(PostType.video, Icons.videocam_rounded, "Video", const Color(0xFFF3E5F5)),
                    ],
                  ),
                  const Divider(height: 30),
                  TextField(
                    controller: _urlController,
                    onChanged: (val) => setState(() {}), // I-refresh ang preview habang nag-e-encode ng URL
                    decoration: InputDecoration(
                      labelText: "${_selectedType == PostType.image ? 'Image' : 'Video'} URL",
                      prefixIcon: const Icon(Icons.link_rounded),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),

            // --- SECTION 3: PREVIEW (Pinapakita ang hitsura ng image/video bago i-post) ---
            if (_urlController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PREVIEW", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: _selectedType == PostType.image
                          ? Image.network(_urlController.text,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => _errorPreview(), // Error handler para sa invalid URL
                      )
                          : Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.black87,
                        child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper function para sa paggawa ng buttons na pampalit ng Post Type (Image o Video)
  Widget _buildTypeSelector(PostType type, IconData icon, String label, Color color) {
    bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.blueAccent : Colors.grey),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.blueAccent : Colors.grey)),
          ],
        ),
      ),
    );
  }

  // Widget na ipapakita kapag hindi ma-load ang image mula sa URL
  Widget _errorPreview() {
    return Container(
      height: 100,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Center(child: Text("Invalid Image URL", style: TextStyle(color: Colors.grey))),
    );
  }
}