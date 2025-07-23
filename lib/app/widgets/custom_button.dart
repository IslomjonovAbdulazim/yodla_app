import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ??
        (isOutlined ? Colors.transparent : AppColors.primary);
    final effectiveTextColor = textColor ??
        (isOutlined ? AppColors.primary : Colors.white);
    final effectiveHeight = height ?? 50;
    final effectivePadding = padding ??
        EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    final effectiveBorderRadius = borderRadius ??
        BorderRadius.circular(25);

    return SizedBox(
      width: width,
      height: effectiveHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveTextColor,
          padding: effectivePadding,
          shape: RoundedRectangleBorder(
            borderRadius: effectiveBorderRadius,
            side: isOutlined
                ? BorderSide(color: AppColors.primary, width: 1.5)
                : BorderSide.none,
          ),
          elevation: isOutlined ? 0 : 2,
          shadowColor: AppColors.primary.withOpacity(0.3),
        ),
        child: isLoading
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isOutlined ? AppColors.primary : Colors.white,
            ),
          ),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: effectiveTextColor,
              ),
              SizedBox(width: 8),
            ],

            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: effectiveTextColor,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Factory constructors for common button styles
  factory CustomButton.primary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    double? height,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      height: height,
      backgroundColor: AppColors.primary,
      textColor: Colors.white,
    );
  }

  factory CustomButton.secondary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    double? height,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      height: height,
      backgroundColor: AppColors.secondary,
      textColor: Colors.white,
    );
  }

  factory CustomButton.outlined({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    double? height,
    Color? borderColor,
    Color? textColor,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isOutlined: true,
      icon: icon,
      width: width,
      height: height,
      textColor: textColor ?? AppColors.primary,
    );
  }

  factory CustomButton.danger({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    double? height,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      height: height,
      backgroundColor: AppColors.error,
      textColor: Colors.white,
    );
  }

  factory CustomButton.success({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    double? height,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      height: height,
      backgroundColor: AppColors.success,
      textColor: Colors.white,
    );
  }

  factory CustomButton.small({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      height: 36,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: BorderRadius.circular(18),
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }

  factory CustomButton.large({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }
}