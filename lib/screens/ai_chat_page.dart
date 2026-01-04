// ai_chat_page.dart - WORKING GEMINI VERSION

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/colors.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({Key? key}) : super(key: key);

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // 🔐 PUT YOUR REAL API KEY HERE
  static const String GEMINI_API_KEY = 'AIzaSyB6ssIOKKTqjeve23CxrOBzVw8chHmiJ3M';

  static const String GEMINI_API_URL =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent';

  @override
  void initState() {
    super.initState();

    if (GEMINI_API_KEY.isEmpty ||
        GEMINI_API_KEY == 'PASTE_YOUR_API_KEY_HERE') {
      _addMessage(
        '❌ Gemini API key not set.\n\n'
        'Go to Google AI Studio → Create API key → paste it here.',
        false,
      );
    } else {
      _addMessage(
        'Hello! 👋 I’m your BharatDoorstep AI assistant.\n\n'
        'I can help with:\n'
        '• Booking services\n'
        '• Payment issues\n'
        '• Technician details\n'
        '• Account support\n\n'
        'How can I help you today?',
        false,
      );
    }
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _isLoading) return;

    _addMessage(message, true);
    _messageController.clear();

    setState(() => _isLoading = true);

    try {
      final reply = await _getAIResponse(message);
      _addMessage(reply, false);
    } catch (e) {
      _addMessage(
        '❌ AI Error:\n${e.toString()}\n\n'
        'Please check:\n'
        '• API key\n'
        '• Internet connection\n'
        '• Gemini API enabled',
        false,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _getAIResponse(String userMessage) async {
    final prompt = '''
You are a helpful customer support AI for BharatDoorstep, an Indian home services app.

Context:
- Verified technicians
- Services: plumbing, electrical, AC repair, cleaning, painting
- Payments: UPI, cards, net banking
- 24/7 support
- 30-day service guarantee

User question: $userMessage

Reply in a friendly, concise way (2–4 sentences).
If personal data is needed, ask them to contact support@bharatdoorstep.com.
''';

    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 300,
      }
    };

    final response = await http.post(
      Uri.parse('$GEMINI_API_URL?key=$GEMINI_API_KEY'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception(
        'Status ${response.statusCode}: ${response.body}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'AI Support Assistant',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageBubble(_messages[index]),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            color: AppColors.primary,
            onPressed: () => _sendMessage(_messageController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment:
          msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.primary : AppColors.bgLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
