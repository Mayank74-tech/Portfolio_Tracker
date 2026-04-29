import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color color;

  const LoadingWidget({
    super.key,
    this.message,
    this.color = const Color(0xFF6366F1),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              color: color,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(
              message!,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
