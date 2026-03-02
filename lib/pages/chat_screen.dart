// ignore_for_file: unused_element, unused_import
import 'package:diana/animations/glowing_logo_loop.dart';
import 'package:diana/animations/splash_screen.dart';
import 'package:diana/pages/drawer.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diana',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isResponding = false;
  bool _stopRequested = false;
  bool _isSpeaking = false;
  bool showIntro = true;
  late AnimationController _speakAnimController;
  late Animation<double> _speakScale;

  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
    _speakAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _speakScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _speakAnimController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    List<dynamic> voices = await _flutterTts.getVoices;

    final preferredVoices = [
      "Google UK English Female",
      "en-us-x-sfg#female_2-local",
      "en-US-language",
      "en-US-Wavenet-F",
      "en-US-Wavenet-D",
      "en-US-Standard-C",
      "com.apple.ttsbundle.Samantha-compact",
    ];

    Map<String, String>? selected;
    for (var voice in voices) {
      if (voice is Map &&
          voice['name'] != null &&
          voice['locale'] != null &&
          preferredVoices.contains(voice['name'])) {
        selected = {"name": voice['name'], "locale": voice['locale']};
        break;
      }
    }

    if (selected != null) {
      await _flutterTts.setLanguage(selected['locale']!);
      await _flutterTts.setVoice(selected);
    }

    if (Theme.of(context).platform == TargetPlatform.android) {
      await _flutterTts.setSpeechRate(0.5);
    } else {
      await _flutterTts.setSpeechRate(0.6);
    }
    await _flutterTts.setPitch(1.3);

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
        _speakAnimController.repeat(reverse: true);
      });
    });
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
        _speakAnimController.stop();
      });
    });
    _flutterTts.setCancelHandler(() {
      setState(() {
        _isSpeaking = false;
        _speakAnimController.stop();
      });
    });
  }

  Future<void> speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isResponding) return;

    if (showIntro) setState(() => showIntro = false);

    setState(() {
      _messages.add({"role": "user", "text": text});
      _controller.clear();
      _messages.add({"role": "bot", "text": "typing"});
      _isResponding = true;
      _stopRequested = false;
    });

    _scrollToBottom();

    // --- GEMINI API CONFIG ---
    const apiKey = 'AIzaSyBLvi0z4jZw2dFVToveSf66_X62ixLHy28';
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
    );

    // Format history: Gemini requires strictly alternating User -> Model
    List<Map<String, dynamic>> contents = [];
    for (var m in _messages) {
      if (m["text"] == "typing") continue;
      contents.add({
        "role": m["role"] == "user" ? "user" : "model",
        "parts": [
          {"text": m["text"]!},
        ],
      });
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"contents": contents}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception("No response generated. (Check Safety Filters)");
        }

        String botText = data['candidates'][0]['content']['parts'][0]['text'];
        botText = botText.trim();

        final int index = _messages.length - 1;
        String displayedText = "";

        for (int i = 0; i < botText.length; i++) {
          if (_stopRequested) break;
          await Future.delayed(const Duration(milliseconds: 6));
          displayedText += botText[i];

          if (mounted) {
            setState(() {
              _messages[index] = {"role": "bot", "text": displayedText};
            });
            _scrollToBottom();
          }
        }
      } else {
        debugPrint("Gemini Error Detail: ${response.body}");
        throw Exception("Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Diana Logic Error: $e");
      if (mounted) {
        setState(() {
          if (_messages.isNotEmpty && _messages.last["text"] == "typing") {
            _messages.removeLast();
          }
          _messages.add({
            "role": "bot",
            "text":
                "Diana couldn't reach the stars. Please check your connection or try again later.",
          });
        });
      }
    } finally {
      if (mounted) setState(() => _isResponding = false);
    }
  }

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

  Widget buildMessageBubble(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';

    return Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            padding: const EdgeInsets.all(14),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: isUser ? Colors.blueAccent : Colors.grey[800],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: isUser
                    ? const Radius.circular(18)
                    : const Radius.circular(4),
                bottomRight: isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(18),
              ),
            ),
            child: msg['text'] == 'typing'
                ? const DotTypingIndicator()
                : Text(
                    msg['text']!,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
        ),
        if (!isUser && msg['text'] != 'typing')
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 2, bottom: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: msg['text']!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Copied"),
                        duration: Duration(milliseconds: 500),
                      ),
                    );
                  },
                ),
                ScaleTransition(
                  scale: _isSpeaking
                      ? _speakScale
                      : const AlwaysStoppedAnimation(1.0),
                  child: IconButton(
                    icon: const Icon(
                      Icons.volume_up,
                      size: 18,
                      color: Colors.grey,
                    ),
                    onPressed: () => speak(msg['text']!),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: RavenDrawer(
        onNewChat: () {
          setState(() {
            _messages.clear();
            showIntro = true;
          });
        },
      ),
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Diana", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF448AFF),
            ),
            onPressed: () {
              setState(() {
                _messages.clear();
                showIntro = true;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) =>
                      buildMessageBubble(_messages[index]),
                ),
                if (showIntro)
                  Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: GlowingLogoLoop(),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Hi, I'm Diana",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Ask me anything...\nI'm always listening 🤍",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Material(
              elevation: 4,
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Ask Anything...",
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: sendMessage,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isResponding ? Icons.stop_circle : Icons.send,
                        color: Colors.blueAccent,
                      ),
                      onPressed: () {
                        if (_isResponding) {
                          setState(() => _stopRequested = true);
                        } else {
                          sendMessage(_controller.text);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DotTypingIndicator extends StatefulWidget {
  const DotTypingIndicator({super.key});
  @override
  State<DotTypingIndicator> createState() => _DotTypingIndicatorState();
}

class _DotTypingIndicatorState extends State<DotTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> dot1, dot2, dot3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    dot1 = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3)),
    );
    dot2 = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.6)),
    );
    dot3 = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget dot(Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, animation.value), child: child),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: CircleAvatar(radius: 4, backgroundColor: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [dot(dot1), dot(dot2), dot(dot3)],
    );
  }
}
