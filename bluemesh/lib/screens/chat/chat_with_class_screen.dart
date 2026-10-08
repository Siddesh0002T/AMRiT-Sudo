import 'package:flutter/material.dart';
import '../../core/config/env_config.dart';
import '../../models/student.dart';
import '../../services/gemini_service.dart';

class ChatWithClassScreen extends StatefulWidget {
  final List<Student>? students;
  final List<Map<String, dynamic>>? attendanceRecords;
  final String userRole; // "Admin" or "Staff"

  const ChatWithClassScreen({
    super.key,
    this.students,
    this.attendanceRecords,
    this.userRole = 'Staff',
  });

  @override
  State<ChatWithClassScreen> createState() => _ChatWithClassScreenState();
}

class _ChatWithClassScreenState extends State<ChatWithClassScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<GeminiMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _quickPrompts = [
    '📊 Summarize today\'s attendance status',
    '❌ Who are the absentees and irregular students?',
    '🖐️ Verify biometric compliance rates',
    '💡 Suggest engaging classroom discussion topics',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(GeminiMessage(
      sender: 'gemini',
      text: '👋 Hello **${widget.userRole}**! I am your BlueMesh Class & Attendance AI Assistant powered by Google Gemini.\n\n'
          'Ask me anything about today\'s roster, student attendance rates, or request a quick summary!',
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _messages.add(GeminiMessage(sender: 'user', text: clean));
      _isLoading = true;
    });
    _scrollToBottom();

    final response = await GeminiService.instance.askGemini(
      prompt: clean,
      students: widget.students,
      attendanceRecords: widget.attendanceRecords,
      conversationHistory: _messages,
    );

    if (mounted) {
      setState(() {
        _messages.add(GeminiMessage(sender: 'gemini', text: response));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: EnvConfig.instance.geminiApiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.key_rounded, color: Color(0xFF38BDF8)),
            SizedBox(width: 8),
            Text('Gemini API Key', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your free Gemini API Key or set it in the `.env` file:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            onPressed: () async {
              await EnvConfig.instance.setGeminiApiKey(controller.text);
              if (ctx.mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gemini API Key updated!')),
              );
            },
            child: const Text('Save Key', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chat with Class', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(
                  'Powered by Gemini · ${widget.userRole} Mode',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            tooltip: 'Configure Gemini API Key',
            onPressed: _showApiKeyDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Prompts Chips
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return ActionChip(
                  label: Text(
                    prompt,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF93C5FD)),
                  ),
                  backgroundColor: const Color(0xFF1E293B),
                  side: BorderSide(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                  onPressed: () => _sendMessage(prompt),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Colors.white12),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.sender == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: isUser ? const Radius.circular(14) : const Radius.circular(4),
                        bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(14),
                      ),
                      border: Border.all(
                        color: isUser ? const Color(0xFF3B82F6) : const Color(0xFF334155),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Gemini AI',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[300],
                                ),
                              ),
                            ],
                          ),
                        if (!isUser) const SizedBox(height: 4),
                        SelectableText(
                          msg.text,
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Gemini is analyzing class context...',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: 'Ask Gemini about attendance, students...',
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
