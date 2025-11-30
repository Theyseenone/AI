import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:ai/models/chat_message.dart';
import 'package:ai/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class ChatgptScreen extends StatefulWidget {
  const ChatgptScreen({super.key});

  @override
  State<ChatgptScreen> createState() => _ChatgptScreenState();
}

class _ChatgptScreenState extends State<ChatgptScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Dio _dio = Dio();

  final List<ChatMessage> _messages = [];
  late FirestoreService _firestoreService;
  String? _conversationId;
  bool _isLoading = false;
  bool _isLoadingChat = true;

  // Hard-coded Ollama settings (change if needed)
  static const String BASE_URL = 'http://localhost:11434';
  static const String MODEL = 'llama3.2:1b';
  static const String API_KEY = ''; // optional

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Ensure auth (main already signed-in, but double-check)
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    // Use uid as conversation id so it's persistent per user
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _conversationId = uid;
    _firestore_serviceInit();
    await _loadChatHistory();
  }

  void _firestore_serviceInit() {
    _firestoreService = FirestoreService(conversationId: _conversationId!);
  }

  Future<void> _loadChatHistory() async {
    try {
      final messages = await _firestoreService.loadChat();
      if (messages.isEmpty) {
        _messages.add(ChatMessage(
          senderId: FirebaseAuth.instance.currentUser!.uid,
          role: 'assistant',
          content: 'Unsay naa sa imu hunahuna karon?',
          timestamp: DateTime.now(),
        ));
      } else {
        _messages.addAll(messages);
      }
    } catch (e) {
      debugPrint('Failed to load chat history: $e');
      _messages.add(ChatMessage(
        senderId: FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        role: 'assistant',
        content: 'Unsay naa sa imu hunahuna karon?',
        timestamp: DateTime.now(),
      ));
    } finally {
      setState(() {
        _isLoadingChat = false;
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _completionFun() async {
    if (!_formKey.currentState!.validate()) return;

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userMsg = ChatMessage(
      senderId: uid,
      role: 'user',
      content: prompt,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });

    _promptController.clear();
    FocusScope.of(context).unfocus();
    _scrollToBottom();

    // Save user message
    try {
      await _firestoreService.saveMessage(userMsg);
    } catch (e) {
      debugPrint('Failed to save user message: $e');
    }

    // Build request messages
    final requestMessages = _messages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    String assistantReply = 'Wala koy tubag karon.';
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (API_KEY.isNotEmpty) headers['Authorization'] = 'Bearer $API_KEY';

      final response = await _dio.post(
        '$BASE_URL/api/chat',
        data: jsonEncode({
          'model': MODEL,
          'messages': requestMessages,
          'stream': false,
        }),
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      // Try to parse typical shapes
      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['choices'] != null && data['choices'] is List && data['choices'].isNotEmpty) {
          assistantReply = data['choices'][0]['content']?.toString() ?? assistantReply;
        } else if (data['message'] != null && data['message']['content'] != null) {
          assistantReply = data['message']['content'].toString();
        } else {
          assistantReply = data.toString();
        }
      } else {
        assistantReply = response.toString();
      }
    } catch (e) {
      debugPrint('Chat completion failed: $e');
      assistantReply = 'Error: $e';
    }

    if (!mounted) return;

    final assistantMsg = ChatMessage(
      senderId: uid,
      role: 'assistant',
      content: assistantReply,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(assistantMsg);
      _isLoading = false;
    });

    _scrollToBottom();

    // Save assistant message
    try {
      await _firestoreService.saveMessage(assistantMsg);
    } catch (e) {
      debugPrint('Failed to save assistant message: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        title: const Text('Llama AI Assistant'),
        backgroundColor: const Color(0xFF0F1419),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingChat
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final m = _messages[index];
                        final isUser = m.role == 'user';
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 360),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isUser ? const Color(0xFF26C485) : const Color(0xFF1A1F2E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              m.content,
                              style: TextStyle(color: isUser ? Colors.white : Colors.green[50]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
                  SizedBox(width: 8),
                  Text('AI is thinking...'),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _promptController,
                      style: const TextStyle(color: Colors.white),
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onFieldSubmitted: (_) => _completionFun(),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter something' : null,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        filled: true,
                        fillColor: const Color(0xFF0A0E12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isLoading ? null : _completionFun,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
