import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/ai_controller.dart';

// ─────────────────────────────────────────────
//  Data models
// ─────────────────────────────────────────────
enum _Role { ai, user }

class _Message {
  final int id;
  final _Role role;
  final String text;
  final String time;
  final bool isTyping;

  const _Message({
    required this.id,
    required this.role,
    required this.text,
    required this.time,
    this.isTyping = false,
  });

  _Message copyWith({bool? isTyping, String? text, String? time}) => _Message(
        id: id,
        role: role,
        text: text ?? this.text,
        time: time ?? this.time,
        isTyping: isTyping ?? this.isTyping,
      );
}

// Initial messages
final _initialMessages = [
  _Message(
    id: 1,
    role: _Role.ai,
    text:
        'Hello! I\'m your AI portfolio assistant powered by Llama 3. I can analyze your holdings, explain market trends, and give you personalized insights. What would you like to know?',
    time: '10:00 AM',
  ),
];

const _suggestions = [
  'Why is my portfolio down?',
  'Which is my best stock?',
  'Should I diversify?',
  'Summarize my portfolio',
];

// ─────────────────────────────────────────────
//  AI Chat Screen
// ─────────────────────────────────────────────
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with TickerProviderStateMixin {
  late final AiController _aiController;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocus = FocusNode();

  // Animation controllers
  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _aiController = Get.find<AiController>();
    _aiController.checkAvailability();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeIn);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
    _headerCtrl.forward();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final trimmed = text.trim();
    _inputController.clear();
    setState(() {});
    await _aiController.sendMessage(trimmed);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<_Message> get _visibleMessages {
    final controllerMessages = _aiController.messages.map((message) {
      final sender = message['sender']?.toString();
      return _Message(
        id: (message['created_at']?.toString() ?? message.hashCode.toString())
            .hashCode,
        role: sender == 'user' ? _Role.user : _Role.ai,
        text: message['message']?.toString() ?? '',
        time: _formatTime(message['created_at']),
      );
    }).toList();

    final messages = [..._initialMessages, ...controllerMessages];
    if (_aiController.isLoading.value) {
      messages.add(
        _Message(
          id: -1,
          role: _Role.ai,
          text: '',
          time: '',
          isTyping: true,
        ),
      );
    }
    return messages;
  }

  String _formatTime(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: const Color(0xFF0B1120),
            body: SafeArea(
              child: Column(
                children: [
                  // ── Header ──
                  FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: _buildHeader(),
                    ),
                  ),
                  // ── Messages ──
                  Expanded(child: _buildMessageList()),
                  // ── Suggestions ──
                  if (!_aiController.isLoading.value &&
                      _visibleMessages.length <= 3)
                    _buildSuggestions(),
                  // ── Input bar ──
                  _buildInputBar(),
                ],
              ),
            ),
          ),
        ));
  }

  // ─────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF130B2E), Colors.transparent],
        ),
        border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: Row(
        children: [
          // Bot avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_outlined,
                size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('AI Assistant',
                        style: TextStyle(
                          color: Color(0xFFF1F5F9),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(width: 8),
                    // Online badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                              _aiController.isAvailable.value
                                  ? 'Online'
                                  : 'Offline',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
                const Text('Powered by Llama 3 · Running locally',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    )),
              ],
            ),
          ),
          const Icon(Icons.auto_awesome_outlined,
              size: 18, color: Color(0xFF818CF8)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  MESSAGE LIST
  // ─────────────────────────────────────────────
  Widget _buildMessageList() {
    final messages = _visibleMessages;
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: messages.length,
      itemBuilder: (ctx, i) {
        return _AnimatedMessageBubble(
          message: messages[i],
          key: ValueKey(messages[i].id),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  //  SUGGESTIONS
  // ─────────────────────────────────────────────
  Widget _buildSuggestions() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _sendMessage(_suggestions[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: const Color(0xFF6366F1).withOpacity(0.25)),
            ),
            child: Text(
              _suggestions[i],
              style: const TextStyle(
                color: Color(0xFF818CF8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  INPUT BAR
  // ─────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          color: const Color(0xFF131D2E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocus,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask about your portfolio...',
                  hintStyle: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                cursorColor: const Color(0xFF6366F1),
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                onChanged: (_) => setState(() {}),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  // Mic
                  const Icon(Icons.mic_none_rounded,
                      size: 18, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  // Send button
                  GestureDetector(
                    onTap: () => _sendMessage(_inputController.text),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _inputController.text.trim().isNotEmpty
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF6366F1).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        size: 16,
                        color: _inputController.text.trim().isNotEmpty
                            ? Colors.white
                            : const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Animated message bubble
// ─────────────────────────────────────────────
class _AnimatedMessageBubble extends StatefulWidget {
  final _Message message;
  const _AnimatedMessageBubble({required this.message, super.key});

  @override
  State<_AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<_AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: Offset(widget.message.role == _Role.user ? 0.1 : -0.1, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _scale = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildBubble(),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble() {
    final isUser = widget.message.role == _Role.user;

    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // AI avatar
        if (!isUser) ...[
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              ),
            ),
            child: const Icon(Icons.smart_toy_outlined,
                size: 14, color: Colors.white),
          ),
        ],

        // Bubble
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.76,
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              gradient: isUser
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    )
                  : null,
              color: isUser ? null : const Color(0xFF1A2640),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
            ),
            child: widget.message.isTyping
                ? _TypingIndicator()
                : _buildTextContent(isUser),
          ),
        ),
      ],
    );
  }

  Widget _buildTextContent(bool isUser) {
    final lines = widget.message.text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...lines.map((line) {
          if (line.isEmpty) return const SizedBox(height: 6);
          return _RichLine(
            line: line,
            color: isUser ? Colors.white : const Color(0xFFE2E8F0),
          );
        }),
        const SizedBox(height: 4),
        Text(
          widget.message.time,
          style: TextStyle(
            color: isUser
                ? Colors.white.withOpacity(0.5)
                : const Color(0xFF475569),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Rich text line (handles **bold**)
// ─────────────────────────────────────────────
class _RichLine extends StatelessWidget {
  final String line;
  final Color color;
  const _RichLine({required this.line, required this.color});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(line)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: line.substring(lastEnd, match.start),
          style: TextStyle(color: color, fontSize: 13, height: 1.5),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          color: color,
          fontSize: 13,
          height: 1.5,
          fontWeight: FontWeight.w700,
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < line.length) {
      spans.add(TextSpan(
        text: line.substring(lastEnd),
        style: TextStyle(color: color, fontSize: 13, height: 1.5),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

// ─────────────────────────────────────────────
//  Typing indicator (3 bouncing dots)
// ─────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: -8).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    // Stagger
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: const BoxDecoration(
                  color: Color(0xFF818CF8),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
