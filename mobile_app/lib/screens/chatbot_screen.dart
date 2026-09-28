/*
 * Production Integration Note:
 * ----------------------------
 * In production deployment, this UI connects directly to the Bhashini API (bhashini.gov.in)
 * for real-time speech-to-text & translation in 22 official Indian languages (including tribal dialects),
 * alongside JAGO voice assistant integration.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? intent;

  ChatMessage({required this.text, required this.isUser, this.intent});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Namaste! I am EkVidya AI Assistant. How can I help you with your Ministry of Tribal Affairs ST Scholarship today?\n\n(Production integrates Bhashini Voice Bot for low-literacy beneficiaries).',
      isUser: false,
      intent: 'welcome',
    ),
  ];
  bool isThinking = false;

  void _sendMessage([String? predefinedText]) async {
    final text = predefinedText ?? _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      isThinking = true;
    });

    final state = Provider.of<AppState>(context, listen: false);
    final res = await state.api.askChatbot(text, state.currentLanguage);

    setState(() {
      isThinking = false;
      _messages.add(ChatMessage(
        text: res['answer'] ?? 'Sorry, I am unable to process that query right now.',
        isUser: false,
        intent: res['matched_intent'],
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isHindi = state.currentLanguage == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            Text(isHindi ? 'एकविद्या एआई सहायक' : 'EkVidya AI Chatbot'),
            const Text(
              'Bhashini Multilingual & JAGO Voice Ready',
              style: TextStyle(fontSize: 10, color: Colors.white70),
            )
          ],
        ),
      ),
      body: Column(
        children: [
          // Suggested Query Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.help_outline, size: 14),
                    label: Text(isHindi ? 'पात्रता नियम' : 'Eligibility Rules'),
                    onPressed: () => _sendMessage('Am I eligible for Post-Matric Scholarship?'),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.description, size: 14),
                    label: Text(isHindi ? 'आवश्यक दस्तावेज' : 'Required Documents'),
                    onPressed: () => _sendMessage('What documents do I need to upload?'),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.account_balance_wallet, size: 14),
                    label: Text(isHindi ? 'डीबीटी भुगतान समय' : 'DBT Payment Timeline'),
                    onPressed: () => _sendMessage('When will scholarship funds be credited?'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Message List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isUser ? const Color(0xFF0D47A1) : Colors.white,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: msg.isUser ? Radius.zero : const Radius.circular(16),
                        bottomLeft: msg.isUser ? const Radius.circular(16) : Radius.zero,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isUser ? Colors.white : Colors.black87,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (isThinking)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Thinking...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic, color: Colors.teal),
                    tooltip: 'Bhashini Voice Input (Demo)',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bhashini Voice Bot active: Listening in Hindi/Santhali...')),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: isHindi ? 'अपना प्रश्न पूछें...' : 'Ask a scholarship question...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.teal.shade800,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
