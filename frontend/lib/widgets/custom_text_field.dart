import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.suffixIcon,
    this.validator,
    this.userType, // 'elderly' | 'student' | 'institution' etc.
  });

  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final String? userType;

  // Helper method to determine focus border color based on userType
  Color _getFocusColor() {
    switch (userType) {
      case 'elderly':
        return const Color(0xFF16A34A); // green-600
      case 'student':
        return Colors.blue;
      case 'institution':
      default:
        return const Color(0xFF4F46E5); // indigo-600 (default)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151), // gray-700
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          validator:
              validator ??
              (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bu alan boş bırakılamaz';
                }
                return null;
              },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)), // gray-400
            prefixIcon: Icon(prefixIcon, color: const Color(0xFF9CA3AF)),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: Color(0xFFD1D5DB),
              ), // gray-300
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: _getFocusColor(), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFEF4444)), // red-500
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
