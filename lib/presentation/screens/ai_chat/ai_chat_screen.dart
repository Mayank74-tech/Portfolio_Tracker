import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/routes/app_routes.dart';

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

  _Message copyWith({bool? isTyping, String? text, String? time}) =>
      _Message(
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

// Canned AI responses
const _aiResponses = {
  'Why is my portfolio down?':
  'Your portfolio dropped mainly due to:\n\n• **INFY** fell -1.5% following broader IT sector weakness\n• **RELIANCE** fell -1.4% due to crude oil price concerns\n\nHowever, TCS (+2.1%) and WIPRO (+1.2%) partially offset these losses. Net today: -₹380 (-0.3%).',
  'Which is my best stock?':
  '🏆 **TCS** is your top performer!\n\n• Current: ₹3,842.50\n• Avg Buy: ₹3,500\n• Return: +₹3,425 (+9.8%)\n\nWIPRO is also performing well with +8.6% returns since purchase.',
  'Should I diversify?':
  '⚠️ **Diversification Alert**\n\n70% of your portfolio is concentrated in the **IT Sector** (TCS, INFY, WIPRO). This increases sector-specific risk.\n\n**Suggestions:**\n• Add FMCG or Healthcare stocks\n• Consider HDFC or ICICI for more banking exposure\n• Gold/Debt allocation can reduce volatility',
  'Summarize my portfolio':
  '📊 **Portfolio Summary**\n\nTotal Value: ₹1,25,430\nTotal Invested: ₹1,20,000\nOverall Profit: +₹5,430 (+4.5%)\nToday\'s Change: +₹2,300 (+1.84%)\n\n5 stocks across 3 platforms\nBest Performer: TCS (+9.8%)\nWorst Performer: RELIANCE (-3.7%)',
};

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
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocus = FocusNode();

  List<_Message> _messages = List.from(_initialMessages);
  bool _isTyping = false;

  // Animation controllers
  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _headerFade =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeIn);
    _headerSlide = Tween<Offset>(
        begin: const Offset(0, -0.1), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _headerCtrl, curve: Curves.easeOutCubic));
    _headerCtrl.forward();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final trimmed = text.trim();
    _inputController.clear();

    final now = TimeOfDay.now();
    final timeStr =
        '${now.hourOfPeriod}:${now.minute.toString().padLeft(2, '0')} ${now.period.name.toUpperCase()}';

    final userMsg = _Message(
      id: DateTime.now().millisecondsSinceEpoch,
      role: _Role.user,
      text: trimmed,
      time: timeStr,
    );
    final typingMsg = _Message(
      id: DateTime.now().millisecondsSinceEpoch + 1,
      role: _Role.ai,
      text: '',
      time: '',
      isTyping: true,
    );

    setState(() {
      _messages = [..._messages, userMsg, typingMsg];
      _isTyping = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final aiText = _aiResponses[trimmed] ??
        'I analyzed your portfolio regarding "$trimmed". Your portfolio shows strong fundamentals with TCS leading at +9.8%. Consider monitoring RELIANCE and INFY closely. Would you like a detailed breakdown?';

    setState(() {
      _messages = _messages
          .where((m) => !m.isTyping)
          .toList()
        ..add(_Message(
          id: DateTime.now().millisecondsSinceEpoch + 2,
          role: _Role.ai,
          text: aiText,
          time: timeStr,
        ));
      _isTyping = false;
    });
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
    return GestureDetector(
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
              if (!_isTyping && _messages.length <= 3)
                _buildSuggestions(),
              // ── Input bar ──
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
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
        border: Border(
            bottom: BorderSide(color: Color(0x0DFFFFFF))),
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
                        color: const Color(0xFF10B981)
                            .withOpacity(0.12),
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
                          const Text('Online',
                              style: TextStyle(
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
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _messages.length,
      itemBuilder: (ctx, i) {
        return _AnimatedMessageBubble(
          message: _messages[i],
          key: ValueKey(_messages[i].id),
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
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color:
                  const Color(0xFF6366F1).withOpacity(0.25)),
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
        border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          color: const Color(0xFF131D2E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: const Color(0xFF6366F1).withOpacity(0.25)),
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
                  contentPadding:
                  EdgeInsets.symmetric(vertical: 14),
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
                    onTap: () =>
                        _sendMessage(_inputController.text),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _inputController.text.trim().isNotEmpty
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF6366F1)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        size: 16,
                        color: _inputController.text
                            .trim()
                            .isNotEmpty
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
  State<_AnimatedMessageBubble> createState() =>
      _AnimatedMessageBubbleState();
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
      begin: Offset(
          widget.message.role == _Role.user ? 0.1 : -0.1, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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
            color: isUser
                ? Colors.white
                : const Color(0xFFE2E8F0),
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
        .map((c) =>
        Tween<double>(begin: 0, end: -8).animate(
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