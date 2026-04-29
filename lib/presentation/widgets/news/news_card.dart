import 'package:flutter/material.dart';
import '../common/glass_container.dart';

class NewsCard extends StatelessWidget {
  final Map<String, dynamic> article;
  final VoidCallback? onTap;

  const NewsCard({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = article['title']?.toString() ?? '';
    final source = article['source']?.toString() ??
        article['entities']?.toString() ??
        '';
    final publishedAt = article['published_at']?.toString() ??
        article['publishedAt']?.toString() ??
        '';
    final sentiment = article['sentiment']?.toString() ?? '';

    Color sentimentColor = const Color(0xFF64748B);
    if (sentiment == 'positive') sentimentColor = const Color(0xFF10B981);
    if (sentiment == 'negative') sentimentColor = const Color(0xFFEF4444);

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: sentimentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (source.isNotEmpty)
                        Text(
                          source,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                      if (source.isNotEmpty && publishedAt.isNotEmpty)
                        const Text(
                          '  ·  ',
                          style: TextStyle(
                              color: Color(0xFF475569), fontSize: 11),
                        ),
                      if (publishedAt.isNotEmpty)
                        Text(
                          _formatDate(publishedAt),
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Color(0xFF475569),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return raw;
    }
  }
}
