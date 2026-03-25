import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';
import '../services/persona_service.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  // 🎮 CONTROLLERS: Handle the text input and the scrolling behavior of the chat list.
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 📝 CHAT HISTORY: A list that stores all messages. It starts with a welcome message from the AI.
  final List<ChatMessage> _messages = [
    ChatMessage(
        text: "Hi! I'm Facetagram AI. Ask me anything about Facebook or Instagram!",
        role: 'model'
    ),
  ];

  // ⏳ LOADING STATE: A boolean to track if the AI is currently generating a response.
  bool _isTyping = false;

  // 📜 AUTO-SCROLL: Moves the view to the latest message whenever the list updates.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ✉️ SEND LOGIC: Handles the process of adding the user's message and fetching the AI's reply.
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return; // Prevent sending empty messages

    setState(() {
      // Add the user's message to the UI immediately
      _messages.add(ChatMessage(text: text, role: 'user'));
      _isTyping = true; // Show the "Thinking" indicator
      _controller.clear(); // Empty the text box
    });
    _scrollToBottom();

    // 🌐 API CALL: Send the whole history and the Persona rules to GeminiService.
    final response = await GeminiService.sendMultiTurnMessage(
      conversationHistory: _messages,
      systemPrompt: PersonaService.systemPrompt,
    );

    setState(() {
      // Add the AI's response to the chat and hide the "Thinking" indicator
      _messages.add(ChatMessage(text: response, role: 'model'));
      _isTyping = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 📱 CHAT LIST: Displays all messages using the list builder.
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                // Build a chat bubble; isUser is true if the role is 'user'
                return _buildChatBubble(msg.text, msg.role == 'user');
              },
            ),
          ),
          // 💭 TYPING INDICATOR: Visible only when the AI is processing.
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(alignment: Alignment.centerLeft, child: Text("AI is thinking...")),
            ),
          // ⌨️ INPUT AREA: Where the user types their message.
          _buildInputField(),
        ],
      ),
    );
  }

  // 🎨 APP BAR: The top header with the Facetagram gradient and icon.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF27121), Color(0xFFE94057), Color(0xFF8A2387)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(
                height: 70,
                width: 100,
                child: Image.asset('assets/images/chat_bot_icon.png', fit: BoxFit.contain),
              ),
              const Text('Facetagram AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
      toolbarHeight: 140,
    );
  }

  // 💬 CHAT BUBBLE WIDGET: Logic for how individual messages look (left for AI, right for User).
  Widget _buildChatBubble(String text, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // Show AI Icon next to model messages
            SizedBox(height: 60, width: 50, child: Image.asset('assets/images/chat_bot_icon.png')),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFE8EAF6) : Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(text, style: TextStyle(color: isUser ? Colors.blue[900] : Colors.black87)),
            ),
          ),
        ],
      ),
    );
  }

  // 🖊️ INPUT FIELD WIDGET: The bottom bar containing the TextField and Send button.
  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(hintText: "Ask about social media...", border: InputBorder.none),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            // Makes the "Send" text look clickable on different platforms
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _sendMessage,
                child: const Text("Send", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}