

import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ai/models/chat_message.dart';
import 'package:ai/services/firestore_service.dart';
import 'package:ai/sidebar.dart';


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

  // Sidebar data
  final List<String> _projects = ['Project 1', 'Project 2', 'Project 3']; // Example projects
  final List<String> _recentChats = ['Chat 1', 'Chat 2', 'Chat 3']; // Example recent chats

  // Ollama settings
  static const String BASE_URL = 'http://localhost:11434';
  String _selectedModel = 'llama3.2:1b';
  static const String API_KEY = ''; // optional

  // Available models
  final List<String> _availableModels = [
    'llama3.2:1b',
    'llama3.2:3b',
    'llama3.1:8b',
    'codellama:7b',
    'mistral:7b',
    'phi3:3.8b',
  ];

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
          content: 'Hello! What\'s on your mind?',
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
        content: 'Hello! What\'s on your mind?',
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

    // Build request messages with system prompt for English responses
    final requestMessages = [
      {'role': 'system', 'content': 'You are a helpful AI assistant. Always respond in clear, proper English. Do not use any other languages or unknown words.'},
      ..._messages.map((m) => {'role': m.role, 'content': m.content})
    ];

    String assistantReply = 'Sorry, I couldn\'t generate a response right now.';
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (API_KEY.isNotEmpty) headers['Authorization'] = 'Bearer $API_KEY';

      final response = await _dio.post(
        '$BASE_URL/api/chat',
        data: jsonEncode({
          'model': _selectedModel,
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

  void _onNewChat() {
    // Logic to start a new chat
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        senderId: FirebaseAuth.instance.currentUser!.uid,
        role: 'assistant',
        content: 'Hello! What\'s on your mind?',
        timestamp: DateTime.now(),
      ));
    });
  }

  void _onSelectProject() {
    // Logic to select a project
    // For now, just print
    debugPrint('Project selected');
  }

  void _onSelectChat(String chat) {
    // Logic to select a chat
    // For now, just print
    debugPrint('Chat selected: $chat');
  }

  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied to clipboard')),
    );
  }

  void _reactToMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reacted!')),
    );
  }

  Future<void> _editMessage(int index, String currentContent) async {
    final TextEditingController editController = TextEditingController(text: currentContent);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Edit your message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(editController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentContent) {
      setState(() {
        _messages[index] = ChatMessage(
          id: _messages[index].id,
          senderId: _messages[index].senderId,
          role: _messages[index].role,
          content: result,
          timestamp: _messages[index].timestamp,
        );
      });

      // Save updated message to Firestore
      try {
        await _firestoreService.saveMessage(_messages[index]);
      } catch (e) {
        debugPrint('Failed to save edited message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save edited message')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // For now, just show a snackbar with the image path
      // In a full implementation, you would process the image and send it to the AI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image selected: ${image.path}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isLargeScreen = screenWidth > 800;

        if (isLargeScreen) {
          // Large screen: Show sidebar alongside chat
          final sidebarWidth = 250.0;
          final chatWidth = screenWidth - sidebarWidth;
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: const Text('Llama AI Assistant', style: TextStyle(color: Colors.black)),
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.lightBlueAccent, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: sidebarWidth,
                    child: Sidebar(
                      onNewChat: _onNewChat,
                      projects: _projects,
                      recentChats: _recentChats,
                      onSelectProject: _onSelectProject,
                      onSelectChat: _onSelectChat,
                    ),
                  ),
                  SizedBox(
                    width: chatWidth,
                    child: _buildChatArea(chatWidth),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Small screen: Use drawer
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: const Text('Llama AI Assistant', style: TextStyle(color: Colors.black)),
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            drawer: Drawer(
              backgroundColor: Colors.white,
              child: Sidebar(
                onNewChat: _onNewChat,
                projects: _projects,
                recentChats: _recentChats,
                onSelectProject: _onSelectProject,
                onSelectChat: _onSelectChat,
              ),
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.lightBlueAccent, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: _buildChatArea(screenWidth),
            ),
          );
        }
      },
    );
  }

  Widget _buildChatArea(double width) {
    return Column(
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
                        child: Column(
                          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: BoxConstraints(maxWidth: width * 0.8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isUser ? Colors.grey.shade200 : Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                m.content,
                                softWrap: true,
                                style: TextStyle(color: isUser ? Colors.black : Colors.white),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isUser) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                                    onPressed: () => _editMessage(index, m.content),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                                    onPressed: () => _copyMessage(m.content),
                                  ),
                                ] else ...[
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                                    onPressed: () => _copyMessage(m.content),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.thumb_up, size: 16, color: Colors.grey),
                                    onPressed: _reactToMessage,
                                  ),
                                ],
                              ],
                            ),
                          ],
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
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _promptController,
                      style: const TextStyle(color: Colors.black),
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onFieldSubmitted: (_) => _completionFun(),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter something' : null,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 173, 163, 163),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Model selector dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: DropdownButton<String>(
                                value: _selectedModel,
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedModel = newValue;
                                    });
                                  }
                                },
                                items: _availableModels.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(color: Colors.black, fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                                dropdownColor: Colors.white,
                                underline: Container(),
                                icon: const Icon(Icons.arrow_drop_down, color: Color.fromARGB(255, 0, 0, 0), size: 16),
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                            // Clip icon
                            IconButton(
                              icon: const Icon(Icons.attach_file, color: Color.fromARGB(255, 0, 0, 0)),
                              onPressed: _pickImage,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isLoading ? null : _completionFun,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
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
    );
  }
}
