import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/ai_controller.dart';
import 'package:smart_portfolio_tracker/presentation/widgets/common/glass_container.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Data models
// ─────────────────────────────────────────────────────────────────────────────

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
}

const _suggestions = [
  '📊 Summarize my portfolio',
  '📉 Why is my portfolio down?',
  '⭐ Which is my best stock?',
  '🔄 Should I diversify?',
  '📈 Top gainers today',
  '🧠 Behavioral analysis',
];

// ─────────────────────────────────────────────────────────────────────────────
//  AI Chat Screen
// ─────────────────────────────────────────────────────────────────────────────

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with SingleTickerProviderStateMixin {
  late final AiController _ai;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocus = FocusNode();

  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;

  // ✅ Track input state without full setState
  final _hasText = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _ai = Get.find<AiController>();
    _ai.checkAvailability();

    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _headerFade = CurvedAnimation(
      parent: _headerCtrl,
      curve: Curves.easeOut,
    );

    _inputController.addListener(() {
      _hasText.value = _inputController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    _headerCtrl.dispose();
    _hasText.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _inputController.clear();
    _inputFocus.unfocus();

    await _ai.sendMessage(trimmed);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<_Message> _buildMessages() {
    final list = <_Message>[
      const _Message(
        id: 0,
        role: _Role.ai,
        text:
        'Hello! I\'m your AI portfolio assistant. I can analyze your holdings, '
            'explain market trends, and give you personalized insights.\n\n'
            'What would you like to know?',
        time: '',
      ),
    ];

    for (final m in _ai.messages) {
      final sender = m['sender']?.toString();
      list.add(_Message(
        id: m.hashCode,
        role: sender == 'user' ? _Role.user : _Role.ai,
        text: m['message']?.toString() ?? '',
        time: _formatTime(m['created_at']),
      ));
    }

    if (_ai.isLoading.value) {
      list.add(const _Message(
        id: -1,
        role: _Role.ai,
        text: '',
        time: '',
        isTyping: true,
      ));
    }

    return list;
  }

  String _formatTime(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '';
    final h = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final m = date.minute.toString().padLeft(2, '0');
    final p = date.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              FadeTransition(
                opacity: _headerFade,
                child: const _ChatHeader(),
              ),

              // ── Messages + Suggestions ──
              Expanded(
                child: Obx(() {
                  final messages = _buildMessages();
                  final showSuggestions =
                      !_ai.isLoading.value && messages.length <= 3;

                  return Column(
                    children: [
                      // ✅ Suggestions ABOVE messages when few messages
                      if (showSuggestions) _buildSuggestions(),

                      // ── Message List ──
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding:
                          const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          itemCount: messages.length,
                          itemBuilder: (_, i) => _MessageBubble(
                            key: ValueKey(messages[i].id),
                            message: messages[i],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),

              // ── Input Bar ──
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Suggestions (FIXED: wrapping chips, not clipped) ──────────────────────

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _suggestions.map((text) {
          return GestureDetector(
            onTap: () => _sendMessage(text.replaceAll(RegExp(r'[^\w\s?]'), '').trim()),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF818CF8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Input Bar (FIXED: proper padding, no text clipping) ───────────────────

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Text Field ──
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
                  contentPadding: EdgeInsets.fromLTRB(16, 14, 8, 14),
                ),
                cursorColor: const Color(0xFF6366F1),
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
              ),
            ),

            // ── Send Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 6, 6, 6),
              child: ValueListenableBuilder<bool>(
                valueListenable: _hasText,
                builder: (_, hasText, __) {
                  return GestureDetector(
                    onTap: () => _sendMessage(_inputController.text),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: hasText
                            ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFF4F46E5),
                          ],
                        )
                            : null,
                        color: hasText
                            ? null
                            : const Color(0xFF6366F1)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: hasText
                            ? Colors.white
                            : const Color(0xFF6366F1)
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// EXTRACTED WIDGETS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// ── Chat Header ─────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF130B2E), Colors.transparent],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          // Bot avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),

          // Title + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'AI Assistant',
                      style: TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(() {
                      final isOnline =
                          Get.find<AiController>().isAvailable.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                color: isOnline
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Powered by Gemini',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Sparkle icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              size: 16,
              color: Color(0xFF818CF8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message Bubble ──────────────────────────────────────────────────────────

class _MessageBubble extends StatefulWidget {
  final _Message message;
  const _MessageBubble({required this.message, super.key});

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    final isUser = widget.message.role == _Role.user;
    _slide = Tween<Offset>(
      begin: Offset(isUser ? 0.08 : -0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == _Role.user;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // AI avatar
              if (!isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8, bottom: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                  ),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ],

              // Bubble
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF4F46E5),
                      ],
                    )
                        : null,
                    color: isUser ? null : const Color(0xFF1A2640),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: widget.message.isTyping
                      ? const _TypingIndicator()
                      : _BubbleContent(
                    text: widget.message.text,
                    time: widget.message.time,
                    isUser: isUser,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bubble Content ──────────────────────────────────────────────────────────

class _BubbleContent extends StatelessWidget {
  final String text;
  final String time;
  final bool isUser;

  const _BubbleContent({
    required this.text,
    required this.time,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isUser ? Colors.white : const Color(0xFFE2E8F0);
    final timeColor = isUser
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF475569);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ SelectableText so user can copy AI responses
        SelectableText.rich(
          _buildRichText(text, textColor),
          style: TextStyle(
            color: textColor,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
        if (time.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            time,
            style: TextStyle(color: timeColor, fontSize: 10),
          ),
        ],
      ],
    );
  }

  // ✅ Handles **bold**, `code`, and bullet points
  static TextSpan _buildRichText(String text, Color baseColor) {
    final spans = <InlineSpan>[];
    final lines = text.split('\n');

    for (int l = 0; l < lines.length; l++) {
      if (l > 0) spans.add(const TextSpan(text: '\n'));

      final line = lines[l];

      // Handle bullet points
      String processLine = line;
      if (line.trimLeft().startsWith('• ') ||
          line.trimLeft().startsWith('- ')) {
        processLine = '  ${line.trimLeft()}';
      }

      // Parse **bold** and `code` within each line
      final regex = RegExp(r'\*\*(.*?)\*\*|`(.*?)`');
      int lastEnd = 0;

      for (final match in regex.allMatches(processLine)) {
        if (match.start > lastEnd) {
          spans.add(TextSpan(
            text: processLine.substring(lastEnd, match.start),
          ));
        }

        if (match.group(1) != null) {
          // **bold**
          spans.add(TextSpan(
            text: match.group(1),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ));
        } else if (match.group(2) != null) {
          // `code`
          spans.add(TextSpan(
            text: match.group(2),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              color: baseColor.withValues(alpha: 0.85),
              backgroundColor: baseColor.withValues(alpha: 0.08),
            ),
          ));
        }

        lastEnd = match.end;
      }

      if (lastEnd < processLine.length) {
        spans.add(TextSpan(
          text: processLine.substring(lastEnd),
        ));
      }
    }

    return TextSpan(children: spans);
  }
}

// ── Typing Indicator ────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
          (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _anims = _ctrls
        .map((c) => Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: c, curve: Curves.easeInOut),
    ))
        .toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 120), () {
        if (mounted) _ctrls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
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
            animation: _anims[i],
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _anims[i].value),
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