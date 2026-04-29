import 'package:flutter/material.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF131D2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 14,
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Ask about your portfolio...',
                  hintStyle: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                cursorColor: const Color(0xFF6366F1),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isLoading ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: isLoading
                      ? [const Color(0xFF2A2A35), const Color(0xFF2A2A35)]
                      : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                ),
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
