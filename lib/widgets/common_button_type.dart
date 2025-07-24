import 'package:flutter/material.dart' hide ButtonType;
import 'package:yodla_app/widgets/colors.dart';

import 'button.dart' hide ButtonType;
import 'color_variables.dart' hide ButtonType;

enum CommonButtonType {
  primary,
  secondary,
  tertiary,
  white,
  radio,
  radioAlt;

  ButtonType getCommonButtonType(BuildContext context) {
    switch (this) {
      case CommonButtonType.primary:
        return context.colors.buttons.primary;
      case CommonButtonType.secondary:
        return context.colors.buttons.secondary;
      case CommonButtonType.tertiary:
        return context.colors.buttons.tertiary;
      case CommonButtonType.white:
        return context.colors.buttons.white;
      case CommonButtonType.radio:
        return context.colors.buttons.radio;
      case CommonButtonType.radioAlt:
        return context.colors.buttons.radioAlt;
    }
  }

  Color getBorderColor(BuildContext context, Button button, bool isPressed) {
    if (button.borderColor != null) return button.borderColor!;
    final type = getCommonButtonType(context);
    return !button.enabled
        ? type.disabled.border
        : (button.selected ?? false)
        ? type.selected.border
        : isPressed
        ? type.pressed.border
        : type.base.border;
  }

  Color getButtonColor(BuildContext context, Button button, bool isPressed) {
    if (button.buttonColor != null) return button.buttonColor!;
    final type = getCommonButtonType(context);
    return !button.enabled
        ? type.disabled.button
        : (button.selected ?? false)
        ? type.pressed.button
        : isPressed
        ? type.pressed.button
        : type.base.button;
  }

  Color getLabelColor(BuildContext context, Button button, bool isPressed) {
    if (button.labelColor != null) return button.labelColor!;
    final type = getCommonButtonType(context);
    return !button.enabled
        ? type.disabled.label
        : (button.selected ?? false)
        ? type.selected.label
        : isPressed
        ? type.pressed.label
        : type.base.label;
  }
}
