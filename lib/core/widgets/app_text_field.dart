import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Material 3 text field. Keeps the original API ([leadingEmoji] accepted but
/// ignored; pass [icon] for a Material prefix icon).
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? leadingEmoji; // ignored
  final IconData? icon;
  final bool obscure;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? formatters;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final Widget? trailing;
  final TextStyle? textStyle;
  final TextAlign textAlign;

  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.leadingEmoji,
    this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.formatters,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.trailing,
    this.textStyle,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      maxLines: maxLines,
      minLines: 1,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: textStyle,
      textAlign: textAlign,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: trailing,
      ),
    );
  }
}
