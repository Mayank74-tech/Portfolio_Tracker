import 'package:flutter/material.dart';
import '../common/glass_container.dart';

class CompanyInfoCard extends StatelessWidget {
  final Map<String, dynamic> profile;

  const CompanyInfoCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile['name']?.toString() ??
        profile['companyName']?.toString() ?? '';
    final industry = profile['finnhubIndustry']?.toString() ??
        profile['industry']?.toString() ??
        profile['sector']?.toString() ?? '';
    final country = profile['country']?.toString() ?? '';
    final exchange = profile['exchange']?.toString() ?? '';
    final marketCap = _toDouble(profile['marketCapitalization']);
    final website = profile['weburl']?.toString() ?? '';
    final description = profile['description']?.toString() ?? '';

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name.isNotEmpty)
            Text(
              name,
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (industry.isNotEmpty) _chip(industry, const Color(0xFF6366F1)),
              if (exchange.isNotEmpty) _chip(exchange, const Color(0xFF10B981)),
              if (country.isNotEmpty) _chip(country, const Color(0xFF64748B)),
            ],
          ),
          if (marketCap > 0) ...[
            const SizedBox(height: 12),
            _infoRow('Market Cap', '₹${_fmt(marketCap)}Cr'),
          ],
          if (website.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow('Website', website),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                height: 1.6,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)}L';
    return v.toStringAsFixed(0);
  }
}
