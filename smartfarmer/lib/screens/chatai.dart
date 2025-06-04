import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:smartfarmer/provider/lang_provider.dart';

class ChatMessage {
  final String text;
  final String time;
  final bool isUserMessage;
  final String? senderName;

  ChatMessage({
    required this.text,
    required this.time,
    required this.isUserMessage,
    this.senderName,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'time': time,
      'isUserMessage': isUserMessage,
      'senderName': senderName,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] as String,
      time: map['time'] as String,
      isUserMessage: map['isUserMessage'] as bool,
      senderName: map['senderName'] as String?,
    );
  }
}

class AiFarmingAssistantScreen extends StatefulWidget {
  const AiFarmingAssistantScreen({super.key});

  @override
  State<AiFarmingAssistantScreen> createState() =>
      _AiFarmingAssistantScreenState();
}

class _AiFarmingAssistantScreenState extends State<AiFarmingAssistantScreen> {
  late List<ChatMessage> _messages;
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  bool _isAiTyping = false;
  String? _errorMessage;
  Timer? _typingTimer;

  // API endpoint
  static const String _chatApiUrl =
      'https://smartfarmer-iogu.onrender.com/chat';
  static const String _chatHistoryKey = 'chat_history';

  @override
  void initState() {
    super.initState();
    _messages = [];
    _loadChatHistory();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final chatHistory = prefs.getStringList(_chatHistoryKey);

    debugPrint('[DEBUG] Loading chat history: $chatHistory');

    setState(() {
      _messages = [];
      if (chatHistory != null && chatHistory.isNotEmpty) {
        try {
          _messages.addAll(
            chatHistory.map((json) {
              final decoded = jsonDecode(json) as Map<String, dynamic>;
              return ChatMessage.fromMap(decoded);
            }).toList(),
          );
          debugPrint('[DEBUG] Loaded ${_messages.length} messages');
        } catch (e) {
          debugPrint('[DEBUG] Error parsing chat history: $e');
        }
      }
      if (_messages.isEmpty) {
        // Add initial greeting if no history exists
        _messages.add(
          ChatMessage(
            senderName: "AI Assistant",
            text: lang.getText('initial_greeting'),
            time: _formatTime(DateTime.now()),
            isUserMessage: false,
          ),
        );
        debugPrint('[DEBUG] Added initial greeting');
      }
    });

    // Save to ensure greeting is persisted
    await _saveChatHistory();
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(lang.getText('clear_chat_history')),
          content: Text(lang.getText('confirm_delete_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(lang.getText('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                lang.getText('delete'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      await _clearChatHistory();
    }
  }

  Future<void> _clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatHistoryKey);
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    setState(() {
      _messages = [
        ChatMessage(
          senderName: "AI Assistant",
          text: lang.getText('initial_greeting'),
          time: _formatTime(DateTime.now()),
          isUserMessage: false,
        ),
      ];
      debugPrint('[DEBUG] Chat history cleared, added greeting');
    });

    // Save to persist the greeting
    await _saveChatHistory();

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.getText('chat_history_cleared')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    final userInput = _textController.text.trim();
    if (userInput.isEmpty) return;

    debugPrint('[DEBUG] Sending message: $userInput');

    // Add user message to chat
    final userMessage = ChatMessage(
      text: userInput,
      time: _formatTime(DateTime.now()),
      isUserMessage: true,
    );

    setState(() {
      _messages.insert(0, userMessage);
      _textController.clear();
      _isAiTyping = true;
      _errorMessage = null;
    });

    // Save immediately after adding user message
    await _saveChatHistory();

    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _isAiTyping) {
        setState(() => _isAiTyping = false);
      }
    });

    try {
      // Prepare chat history (last 10 messages)
      final recentMessages = _messages.reversed.take(10).toList();
      final chatHistory = recentMessages
          .map(
            (msg) =>
                msg.isUserMessage ? "User: ${msg.text}" : "AI: ${msg.text}",
          )
          .join('\n');

      debugPrint('[DEBUG] Chat history being sent:\n$chatHistory');

      // Build URL with query parameters
      final uri = Uri.parse(_chatApiUrl).replace(
        queryParameters: {'user_input': userInput, 'user_history': chatHistory},
      );

      debugPrint('[DEBUG] API Endpoint with query params: $uri');

      // Use POST instead of GET
      final response = await http
          .post(uri)
          .timeout(const Duration(seconds: 30));

      debugPrint('[DEBUG] API Response Status: ${response.statusCode}');
      debugPrint('[DEBUG] API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        String messageContent;

        try {
          final responseData = json.decode(response.body);
          debugPrint('[DEBUG] Parsed JSON Response: $responseData');

          messageContent =
              responseData['message'] ??
              responseData['response'] ??
              responseData['text'] ??
              response.body;
        } catch (e) {
          debugPrint(
            '[DEBUG] Failed to parse JSON, using raw response. Error: $e',
          );
          messageContent = response.body;
        }

        messageContent =
            messageContent
                .replaceAll(r'\n', '\n')
                .replaceAll('\\"', '"')
                .trim();

        debugPrint('[DEBUG] Final message content: $messageContent');

        final aiResponse = ChatMessage(
          senderName: "AI Assistant",
          text: messageContent,
          time: _formatTime(DateTime.now()),
          isUserMessage: false,
        );

        setState(() {
          _isAiTyping = false;
          _messages.insert(0, aiResponse);
        });

        // Save after adding AI response
        await _saveChatHistory();
        debugPrint('[DEBUG] Message saved to chat history');
      } else {
        debugPrint(
          '[DEBUG] API request failed with status: ${response.statusCode}',
        );
        setState(() {
          _isAiTyping = false;
          _errorMessage = 'Request failed with status: ${response.statusCode}';
        });
      }
    } on http.ClientException catch (e) {
      debugPrint('[DEBUG] Network error: $e');
      setState(() {
        _isAiTyping = false;
        _errorMessage = 'Network error, try again.';
      });
    } on TimeoutException {
      debugPrint('[DEBUG] Request timed out');
      setState(() {
        _isAiTyping = false;
        _errorMessage = 'Request timed out. Please try again.';
      });
    } catch (e) {
      debugPrint('[DEBUG] Unexpected error: $e');
      setState(() {
        _isAiTyping = false;
        _errorMessage = 'Request error. Please try again later.';
      });
    } finally {
      _typingTimer?.cancel();
      debugPrint('[DEBUG] Request processing completed');
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = _messages.map((msg) => jsonEncode(msg.toMap())).toList();
    final success = await prefs.setStringList(_chatHistoryKey, history);
    debugPrint(
      '[DEBUG] Chat history save ${success ? 'successful' : 'failed'}: $history',
    );
  }

  // Helper to format time as "3:03:14 PM"
  static String _formatTime(DateTime time) {
    return '${time.hour > 12 ? time.hour - 12 : time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: true);
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _showDeleteConfirmationDialog,
            tooltip: lang.getText('clear_chat_history'),
          ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.getText('ai_farming_assistant'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              lang.getText('powered_by_agricultural_intelligence'),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildTopInfoBar(),
          if (_errorMessage != null) _buildErrorBanner(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              reverse: true,
              itemCount: _messages.length + (_isAiTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isAiTyping && index == 0) {
                  return _buildTypingIndicator();
                }
                return _buildMessageItem(
                  _messages[_isAiTyping ? index - 1 : index],
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 10),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red[100],
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildTopInfoBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    if (message.isUserMessage) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: accentGreen,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Text(
                  message.time,
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: accentGreen,
              radius: 20,
              child: Icon(Icons.add, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.senderName != null)
                          Text(
                            message.senderName!,
                            style: const TextStyle(
                              color: aiSenderNameColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        if (message.senderName != null)
                          const SizedBox(height: 4),
                        Text(
                          message.text,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            message.time,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildInputArea() {
    final lang = Provider.of<LanguageProvider>(context, listen: true);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      color: scaffoldBackgroundColor,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: lang.getText('ask_farming_question'),
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: const BorderSide(
                        color: accentGreen,
                        width: 1.5,
                      ),
                    ),
                  ),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _isAiTyping ? null : _sendMessage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accentGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            lang.getText('ai_assistant_info'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // Define colors for consistency
  static const Color appBarColor = Color(0xFF66BB6A);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color aiSenderNameColor = Color(0xFF4CAF50);
  static const Color scaffoldBackgroundColor = Color(0xFFF7F7F7);
  static const Color greenDotColor = Color(0xFF81C784);
}
