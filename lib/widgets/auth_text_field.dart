import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final fillColor = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    final borderColor = CupertinoColors.systemGrey4.resolveFrom(context);
    final radius = BorderRadius.circular(14);
    OutlineInputBorder makeBorder(Color color, double width) =>
        OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: color, width: width));

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: CupertinoColors.placeholderText, fontSize: 16),
        filled: true,
        fillColor: fillColor,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: CupertinoColors.systemGrey, size: 20) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: makeBorder(borderColor, 0.5),
        enabledBorder: makeBorder(borderColor, 0.5),
        focusedBorder: makeBorder(Theme.of(context).colorScheme.primary, 1.5),
        errorBorder: makeBorder(CupertinoColors.systemRed, 1),
        focusedErrorBorder: makeBorder(CupertinoColors.systemRed, 1.5),
      ),
    );
  }
}
