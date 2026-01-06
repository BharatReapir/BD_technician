
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class QAChatPage extends StatefulWidget {
  const QAChatPage({Key? key}) : super(key: key);

  @override
  State<QAChatPage> createState() => _QAChatPageState();
}

class _QAChatPageState extends State<QAChatPage> {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  // Predefined Q&A pairs
  final Map<String, String> _qaDatabase = {
    'how to book': 'To book a service:\n1. Go to Home page\n2. Select service category\n3. Choose your service\n4. Pick date & time\n5. Confirm booking',
    'payment methods': 'We accept:\n• UPI (PhonePe, Google Pay, Paytm)\n• Credit/Debit Cards\n• Net Banking\n• Cash on Service',
    'cancel booking': 'To cancel:\n1. Go to My Bookings\n2. Select booking\n3. Click Cancel\n4. Refund in 5-7 days',
    'service guarantee': 'We provide:\n• 30-day service guarantee\n• Verified technicians\n• Quality assurance\n• Free rework if issues',
    'contact support': 'Contact us:\n📧 support@bharatdoorstep.com\n📞 1800-123-4567\n⏰ 24/7 Support Available',
    'technician details': 'All technicians are:\n• Background verified\n• Trained professionals\n• Rated by customers\n• Insured for your safety',
    'service areas': 'Currently serving major cities:\n• Mumbai\n• Delhi\n• Bangalore\n• Hyderabad\n• Chennai\n• Pune',
  };

  @override
  void initState() {
    super.initState();
    _addMessage(
      'Hello! 👋 Welcome to BharatDoorstep Support.\n\n'
      'Select a question below to get instant answers:',
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

  void _handleQuestionTap(String question) {
    // Add user question
    _addMessage(question, true);
    
    // Find and add answer
    final answer = _findAnswer(question);
    Future.delayed(const Duration(milliseconds: 500), () {
      _addMessage(answer, false);
    });
  }

  String _findAnswer(String question) {
    final lowerQuestion = question.toLowerCase();
    
    for (var entry in _qaDatabase.entries) {
      if (lowerQuestion.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return 'Sorry, I don\'t have an answer for that.\n\n'
           'Please contact support:\n'
           '📧 support@bharatdoorstep.com\n'
           '📞 1800-123-4567';
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
          _buildQuestionButtons(),
        ],
      ),
    );
  }

  Widget _buildQuestionButtons() {
    final questions = [
      '❓ How to book a service?',
      '💳 Payment methods',
      '❌ Cancel booking',
      '✅ Service guarantee',
      '📞 Contact support',
      '👨‍🔧 Technician details',
      '📍 Service areas',
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Common Questions:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: questions.map((q) => _buildQuestionChip(q)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionChip(String question) {
    return InkWell(
      onTap: () => _handleQuestionTap(question),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Text(
          question,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
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
        padding: const EdgeInsets.all(12),
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
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}