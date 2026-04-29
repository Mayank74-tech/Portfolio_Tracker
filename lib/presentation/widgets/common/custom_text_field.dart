import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'glass_container.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final int? maxLines;
  final bool readOnly;

  const CustomTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onTap,
    this.maxLines = 1,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
        ],
        GlassContainer(
          borderRadius: BorderRadius.circular(14),
          borderColor: hasError ? const Color(0xFFEF4444).withValues(alpha: 0.5) : null,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            onTap: onTap,
            readOnly: readOnly,
            maxLines: maxLines,
            style: const TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
            ),
            cursorColor: const Color(0xFF6366F1),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
