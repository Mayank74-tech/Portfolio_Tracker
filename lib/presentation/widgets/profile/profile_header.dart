import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String? name;
  final String? email;
  final String? photoUrl;

  const ProfileHeader({
    super.key,
    this.name,
    this.email,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name?.isNotEmpty == true ? name! : 'Investor';
    final initials = displayName
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Row(
      children: [
        // Avatar
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            ),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: photoUrl != null && photoUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _initialsWidget(initials),
                  ),
                )
              : _initialsWidget(initials),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (email != null && email!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email!,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _initialsWidget(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
