// simple_qa_chat_page.dart

import 'package:flutter/material.dart';
import '../constants/colors.dart';

class QAChatPage extends StatefulWidget {
  const QAChatPage({Key? key}) : super(key: key);

  @override
  State<QAChatPage> createState() => _QAChatPageState();
}

class _QAChatPageState extends State<QAChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  // Predefined Q&A database with keywords
  final Map<String, String> _qaDatabase = {
    // Booking related
    'book|booking|how to book|book service': 
        'To book a service:\n1. Go to Home page\n2. Select service category\n3. Choose your service\n4. Pick date & time\n5. Confirm booking\n\nNeed help with booking? Call us at 1800-123-4567',
    
    // Payment related
    'payment|pay|payment method|upi|card|netbanking': 
        'We accept:\n• UPI (PhonePe, Google Pay, Paytm)\n• Credit/Debit Cards\n• Net Banking\n• Cash on Service\n\nAll payments are secure and encrypted.',
    
    // Cancellation
    'cancel|cancellation|cancel booking|refund': 
        'To cancel your booking:\n1. Go to My Bookings\n2. Select the booking\n3. Click Cancel button\n4. Refund in 5-7 working days\n\nNote: Cancellation charges may apply based on timing.',
    
    // Service guarantee
    'guarantee|warranty|quality|not satisfied': 
        'We provide:\n• 30-day service guarantee\n• Verified technicians\n• Quality assurance\n• Free rework if issues persist\n\nYour satisfaction is our priority!',
    
    // Contact support
    'contact|support|help|call|email|customer care': 
        'Contact us:\n📧 support@bharatdoorstep.com\n📞 1800-123-4567\n⏰ 24/7 Support Available\n\nWe\'re always here to help!',
    
    // Technician details
    'technician|worker|professional|verified|background check': 
        'All our technicians are:\n• Background verified\n• Trained professionals\n• Rated by customers\n• Insured for your safety\n• Carry ID cards\n\nYour safety is our priority.',
    
    // Service areas
    'area|location|city|where|service area|available': 
        'Currently serving:\n• Mumbai\n• Delhi NCR\n• Bangalore\n• Hyderabad\n• Chennai\n• Pune\n• Kolkata\n• Ahmedabad\n\nExpanding to more cities soon!',
    
    // Pricing
    'price|cost|charge|rate|expensive|cheap': 
        'Our pricing:\n• Transparent pricing\n• No hidden charges\n• Competitive rates\n• Pay after service\n\nView exact prices when booking. Different services have different rates.',
    
    // Timing
    'time|timing|schedule|when|slot|appointment': 
        'Service timings:\n• Morning: 8 AM - 12 PM\n• Afternoon: 12 PM - 4 PM\n• Evening: 4 PM - 8 PM\n\nChoose your preferred slot while booking!',
    
    // Account issues
    'account|login|password|otp|signup|register': 
        'Account help:\n• Login with mobile number\n• OTP verification required\n• Forgot password? Use OTP login\n• Update profile in Settings\n\nStill facing issues? Contact support.',
  };

  @override
  void initState() {
    super.initState();
    _addMessage(
      'Hello! 👋 Welcome to BharatDoorstep Support.\n\n'
      'Ask me anything about our services, booking, payments, or any help you need!\n\n'
      'You can also click the quick questions below.',
      false,
    );
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

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;
    
    // Add user message
    _addMessage(message, true);
    _messageController.clear();
    
    // Get answer after short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      final answer = _findAnswer(message);
      _addMessage(answer, false);
    });
  }

  String _findAnswer(String question) {
    final lowerQuestion = question.toLowerCase().trim();
    
    // Search through all Q&A entries
    for (var entry in _qaDatabase.entries) {
      final keywords = entry.key.split('|');
      
      // Check if any keyword matches
      for (var keyword in keywords) {
        if (lowerQuestion.contains(keyword.trim())) {
          return entry.value;
        }
      }
    }
    
    // No match found
    return '🤔 I couldn\'t find a specific answer for that.\n\n'
           'Please try asking about:\n'
           '• Booking services\n'
           '• Payments & refunds\n'
           '• Technician details\n'
           '• Service areas\n'
           '• Contact support\n\n'
           'Or contact us directly:\n'
           '📞 1800-123-4567\n'
           '📧 support@bharatdoorstep.com';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Support Q&A',
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
          _buildQuickQuestions(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your question...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.bgMedium),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.bgMedium),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    final quickQuestions = [
      'How to book?',
      'Payment methods',
      'Cancel booking',
      'Contact support',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: quickQuestions
              .map((q) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildQuickQuestionChip(q),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildQuickQuestionChip(String question) {
    return InkWell(
      onTap: () => _sendMessage(question),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Text(
          question,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.primary : AppColors.bgLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : AppColors.textDark,
            fontSize: 14,
            height: 1.4,
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