import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

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
      text: 'Namaste! I am EkVidya AI Assistant. How can I help you with your Ministry of Tribal Affairs ST Scholarship today?',
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
    final res = await state.api.askChatbot(text, state.currentLanguage, studentId: state.studentId);

    setState(() {
      isThinking = false;
      _messages.add(ChatMessage(
        text: res['answer'] ?? (state.currentLanguage == 'hi'
            ? 'क्षमा करें, सर्वर इस समय उत्तर देने में असमर्थ है।'
            : 'Sorry, I am unable to process that query right now.'),
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
      backgroundColor: AppTheme.bgSlate,
      appBar: AppBar(
        backgroundColor: AppTheme.accentTeal,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isHindi ? 'एकविद्या एआई सहायक' : 'EkVidya AI Chatbot', style: const TextStyle(fontSize: 16)),
            const Text(
              'AI Assistant — Multilingual, JAGO-compatible',
              style: TextStyle(fontSize: 10, color: Colors.white70),
            )
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick Action Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.help_outline_rounded, size: 14, color: AppTheme.accentTeal),
                    label: Text(isHindi ? 'पात्रता नियम' : 'Eligibility Rules', style: const TextStyle(fontSize: 12)),
                    onPressed: () => _sendMessage(isHindi ? 'पोस्ट-मैट्रिक छात्रवृत्ति की क्या पात्रता है?' : 'What are the eligibility rules for Post-Matric Scholarship?'),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.description_outlined, size: 14, color: AppTheme.accentTeal),
                    label: Text(isHindi ? 'आवश्यक दस्तावेज' : 'Required Documents', style: const TextStyle(fontSize: 12)),
                    onPressed: () => _sendMessage(isHindi ? 'पोस्ट-मैट्रिक के लिए क्या दस्तावेज चाहिए?' : 'What documents do I need for my Post-Matric application?'),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.account_balance_wallet_outlined, size: 14, color: AppTheme.accentTeal),
                    label: Text(isHindi ? 'डीबीटी भुगतान स्थिति' : 'DBT Payment Status', style: const TextStyle(fontSize: 12)),
                    onPressed: () => _sendMessage(isHindi ? 'मेरी छात्रवृत्ति राशि डीबीटी द्वारा कब जमा होगी?' : 'When will my scholarship amount be credited via DBT?'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Message List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.80,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isUser ? AppTheme.primaryBlue : Colors.white,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: msg.isUser ? Radius.zero : const Radius.circular(16),
                        bottomLeft: msg.isUser ? const Radius.circular(16) : Radius.zero,
                      ),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isUser ? Colors.white : AppTheme.textDark,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (isThinking)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentTeal)),
                  const SizedBox(width: 8),
                  Text(
                    isHindi ? 'Groq AI उत्तर तैयार कर रहा है...' : 'Groq AI grounding query in DB context...',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),

          // Input Bar with Keyboard Safe Area
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic_rounded, color: AppTheme.accentTeal),
                    tooltip: 'AI Voice Input',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isHindi ? 'एआई वॉयस मोड: जेएजीओ संगत इनपुट सुना जा रहा है...' : 'AI Voice Assistant: JAGO-compatible voice mode ready.'),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: isHindi ? 'अपना प्रश्न पूछें...' : 'Ask a scholarship question...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.accentTeal,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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
