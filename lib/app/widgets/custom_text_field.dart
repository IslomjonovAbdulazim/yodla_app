import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final String? initialValue;
  final bool autofocus;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final BorderRadius? borderRadius;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.inputFormatters,
    this.initialValue,
    this.autofocus = false,
    this.contentPadding,
    this.fillColor,
    this.borderRadius,
  });


  // Factory constructors for common field types
  factory CustomTextField.email({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hint,
    String? errorText,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    bool enabled = true,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      label: label ?? 'Email',
      hint: hint ?? 'Enter your email address',
      errorText: errorText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      prefixIcon: Icons.email_outlined,
    );
  }

  factory CustomTextField.password({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hint,
    String? errorText,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    bool enabled = true,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      label: label ?? 'Password',
      hint: hint ?? 'Enter your password',
      errorText: errorText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      obscureText: true,
      textInputAction: TextInputAction.done,
      prefixIcon: Icons.lock_outlined,
    );
  }

  factory CustomTextField.search({
    Key? key,
    TextEditingController? controller,
    String? hint,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onClear,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      hint: hint ?? 'Search...',
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      prefixIcon: Icons.search,
      suffixIcon: onClear != null ? Icons.clear : null,
      onSuffixTap: onClear,
    );
  }

  factory CustomTextField.multiline({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hint,
    String? errorText,
    int? maxLines,
    int? maxLength,
    ValueChanged<String>? onChanged,
    bool enabled = true,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      onChanged: onChanged,
      enabled: enabled,
      maxLines: maxLines ?? 4,
      minLines: 3,
      maxLength: maxLength,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }

  factory CustomTextField.number({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hint,
    String? errorText,
    ValueChanged<String>? onChanged,
    bool enabled = true,
    bool allowDecimals = false,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      onChanged: onChanged,
      enabled: enabled,
      keyboardType: allowDecimals
          ? TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: allowDecimals
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : [FilteringTextInputFormatter.digitsOnly],
    );
  }

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;

    // Add focus listener if focusNode is provided
    widget.focusNode?.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.focusNode?.hasFocus ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveContentPadding = widget.contentPadding ??
        EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    final effectiveFillColor = widget.fillColor ?? AppColors.surface;
    final effectiveBorderRadius = widget.borderRadius ??
        BorderRadius.circular(12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
        ],

        // Text Field
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          obscureText: _obscureText,
          maxLines: _obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofocus: widget.autofocus,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          style: TextStyle(
            fontSize: 16,
            color: widget.enabled ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),

            // Prefix Icon
            prefixIcon: widget.prefixIcon != null
                ? Icon(
              widget.prefixIcon,
              size: 20,
              color: _isFocused
                  ? AppColors.primary
                  : AppColors.textSecondary,
            )
                : null,

            // Suffix Icon
            suffixIcon: _buildSuffixIcon(),

            // Fill
            filled: true,
            fillColor: widget.enabled
                ? effectiveFillColor
                : AppColors.textSecondary.withOpacity(0.1),

            // Content Padding
            contentPadding: effectiveContentPadding,

            // Borders
            border: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: widget.errorText != null
                  ? BorderSide(color: AppColors.error, width: 1)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(
                color: widget.errorText != null
                    ? AppColors.error
                    : AppColors.primary,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),

            // Error text handled separately for better styling
            errorText: null,

            // Counter
            counterText: widget.maxLength != null ? null : '',
          ),
        ),

        // Error Text
        if (widget.errorText != null) ...[
          SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.error,
            ),
          ),
        ],

        // Helper Text
        if (widget.helperText != null && widget.errorText == null) ...[
          SizedBox(height: 4),
          Text(
            widget.helperText!,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    // Password visibility toggle
    if (widget.obscureText) {
      return IconButton(
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          size: 20,
          color: AppColors.textSecondary,
        ),
      );
    }

    // Custom suffix icon
    if (widget.suffixIcon != null) {
      return IconButton(
        onPressed: widget.onSuffixTap,
        icon: Icon(
          widget.suffixIcon,
          size: 20,
          color: _isFocused
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
      );
    }

    return null;
  }
}