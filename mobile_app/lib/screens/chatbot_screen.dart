import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? intent;

  ChatMessage({required this.text, required this.isUser, this.intent});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Namaste! I am EkVidya AI Assistant. How can I help you with your Ministry of Tribal Affairs ST Scholarship today?',
      isUser: false,
      intent: 'welcome',
    ),
  ];
  bool isThinking = false;

  // Speech-to-Text (Voice Input)
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _currentLocaleId = 'en_IN';

  // Text-to-Speech (Voice Output)
  final FlutterTts _flutterTts = FlutterTts();
  int? _currentlySpeakingIndex;

  // Pulse animation for listening state
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _initSpeech() async {
    try {
      bool available = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      if (mounted) {
        setState(() {
          _speechEnabled = available;
        });
      }
    } catch (e) {
      debugPrint("SpeechToText init error: $e");
    }
  }

  void _initTts() {
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _currentlySpeakingIndex = null;
        });
      }
    });
    _flutterTts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          _currentlySpeakingIndex = null;
        });
      }
    });
    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _currentlySpeakingIndex = null;
        });
      }
    });
  }

  void _onSpeechStatus(String status) {
    if (status == 'notListening' || status == 'done') {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (mounted) {
      setState(() {
        _isListening = false;
      });
      _pulseController.stop();
      _pulseController.reset();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice recognition note: ${error.errorMsg}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _toggleListening() async {
    if (!mounted) return;
    final state = Provider.of<AppState>(context, listen: false);
    final isHindi = state.currentLanguage == 'hi';

    if (_isListening) {
      await _speechToText.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
        });
        _pulseController.stop();
        _pulseController.reset();
      }
      return;
    }

    // 1. Request microphone permission gracefully
    var permissionStatus = await Permission.microphone.status;
    if (!permissionStatus.isGranted) {
      permissionStatus = await Permission.microphone.request();
      if (!permissionStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isHindi
                  ? 'वॉयस इनपुट के लिए माइक्रोफ़ोन अनुमति आवश्यक है।'
                  : 'Microphone permission is required for voice input.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    // 2. Initialize if not ready
    if (!_speechEnabled) {
      bool available = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      _speechEnabled = available;
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isHindi
                  ? 'इस डिवाइस पर वाक् पहचान उपलब्ध नहीं है।'
                  : 'Speech recognition is not available on this device.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    // 3. Select target locale
    _currentLocaleId = isHindi ? 'hi_IN' : 'en_IN';

    // 4. Start listening & pulsing
    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenOptions: SpeechListenOptions(
          localeId: _currentLocaleId,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
        ),
      );

      if (mounted) {
        setState(() {
          _isListening = true;
        });
        _pulseController.repeat(reverse: true);
      }
    } catch (e) {
      debugPrint("Speech error: $e");
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (mounted) {
      setState(() {
        _controller.text = result.recognizedWords;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      });
    }
  }

  Future<void> _speakMessage(int index, String text) async {
    if (!mounted) return;
    final state = Provider.of<AppState>(context, listen: false);
    final isHindi = state.currentLanguage == 'hi';
    final ttsLang = isHindi ? 'hi-IN' : 'en-IN';

    if (_currentlySpeakingIndex == index) {
      await _flutterTts.stop();
      if (mounted) {
        setState(() {
          _currentlySpeakingIndex = null;
        });
      }
    } else {
      await _flutterTts.stop();
      await _flutterTts.setLanguage(ttsLang);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      if (mounted) {
        setState(() {
          _currentlySpeakingIndex = index;
        });
      }
      await _flutterTts.speak(text);
    }
  }

  void _sendMessage([String? predefinedText]) async {
    final text = predefinedText ?? _controller.text.trim();
    if (text.isEmpty) return;

    if (_isListening) {
      await _speechToText.stop();
      _pulseController.stop();
      _pulseController.reset();
      _isListening = false;
    }

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      isThinking = true;
    });

    if (!mounted) return;
    final state = Provider.of<AppState>(context, listen: false);
    final res = await state.api.askChatbot(text, state.currentLanguage, studentId: state.studentId);

    if (mounted) {
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
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
    _pulseController.dispose();
    _controller.dispose();
    super.dispose();
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
            Text(
              isHindi ? 'एआई सहायक — वॉयस और बहुभाषी' : 'AI Assistant — Voice & Multilingual',
              style: const TextStyle(fontSize: 10, color: Colors.white70),
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
                final isSpeaking = _currentlySpeakingIndex == index;

                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isUser ? AppTheme.primaryBlue : Colors.white,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: msg.isUser ? Radius.zero : const Radius.circular(16),
                        bottomLeft: msg.isUser ? const Radius.circular(16) : Radius.zero,
                      ),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.text,
                          style: TextStyle(
                            color: msg.isUser ? Colors.white : AppTheme.textDark,
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                        if (!msg.isUser) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () => _speakMessage(index, msg.text),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSpeaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                                        size: 16,
                                        color: isSpeaking ? Colors.redAccent : AppTheme.accentTeal,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isSpeaking
                                            ? (isHindi ? 'रोकें' : 'Stop')
                                            : (isHindi ? 'सुनें' : 'Listen'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isSpeaking ? Colors.redAccent : AppTheme.accentTeal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
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
                    isHindi ? 'एकविद्या एआई उत्तर तैयार कर रहा है...' : 'EkVidya AI grounding query in DB context...',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),

          // Listening Indicator Banner
          if (_isListening)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.redAccent.withValues(alpha: 0.1),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isHindi
                          ? 'सुन रहा हूँ ($_currentLocaleId)... कृपया अपना प्रश्न बोलें'
                          : 'Listening ($_currentLocaleId)... Speak your question now',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isHindi ? 'रोकें' : 'Stop',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
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
                  ScaleTransition(
                    scale: _isListening ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                    child: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isListening ? Colors.redAccent : AppTheme.accentTeal,
                      ),
                      tooltip: _isListening ? 'Stop Listening' : 'AI Voice Input',
                      onPressed: _toggleListening,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? (isHindi ? 'आपकी आवाज सुनी जा रही है...' : 'Listening to your voice...')
                            : (isHindi ? 'अपना प्रश्न पूछें या माइक दबाएं...' : 'Ask a question or tap mic...'),
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
