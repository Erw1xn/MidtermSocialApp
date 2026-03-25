class ChatMessage {
  final String text;
  final String role; // 'user' for you, 'model' for the AI

  ChatMessage({required this.text, required this.role});

  // Helper to convert to JSON for local storage later
  Map<String, dynamic> toJson() => {'text': text, 'role': role};

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      ChatMessage(text: json['text'], role: json['role']);
}