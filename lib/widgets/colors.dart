import 'package:flutter/material.dart';

import 'color_variables.dart';

extension BuildContextExt on BuildContext {
  ZehnlyColors get colors => ZehnlyColors();
}

class ZehnlyColors {
  static final _instance = ZehnlyColors._();

  factory ZehnlyColors() => _instance;

  ZehnlyColors._();

  final foreground = Foreground();
  final border = ZehnlyBorder();
  final text = ZehnlyText();
  final background = Background();
  final flashcards = Flashcards();
  final progress = ProgressColors();
  final cards = CardColors();
  final field = Field();
  final utility = Utility();

  ButtonColors get buttons => ButtonColors(
    primary: ButtonType(
      base: ButtonState(
        button: foreground.brand.secondary,
        label: foreground.white,
        border: foreground.brand.primary,
      ),
      disabled: ButtonState(
        button: background.disabled,
        label: foreground.disabled,
        border: background.disabled,
      ),
    ),
    secondary: ButtonType(
      base: ButtonState(
        button: foreground.white,
        label: foreground.primary,
        border: border.secondary,
      ),
      disabled: ButtonState(
        button: Colors.white.withValues(alpha: 0.2),
        label: text.primary,
        border: Colors.white.withValues(alpha: 0.12),
      ),
    ),
    tertiary: ButtonType(
      base: ButtonState(label: foreground.brand.secondary),
      disabled: ButtonState(label: foreground.disabled),
      error: ButtonState(label: IbratColors.red10),
      success: ButtonState(label: IbratColors.green10),
    ),
    radio: ButtonType(
      base: ButtonState(
        button: foreground.white,
        label: foreground.primary,
        border: border.secondary,
      ),
      disabled: ButtonState(
        button: background.disabled,
        label: foreground.disabled,
        border: background.disabled,
      ),
      selected: ButtonState(
        button: foreground.white,
        label: foreground.brand.secondary,
        border: foreground.brand.primary,
      ),
    ),
  );
}

class Utility {
  final yellow = Color(0xFFFAC515);
}

class Foreground {
  final brand = Brand();
  final warning = Warning();
  final success = Success();
  final error = Error();

  final white = Color(0xFFFFFFFF);
  final primary = Color(0xFF181D27);
  final tertiary = Color(0xFF535862);
  final quaternary = Color(0xFF717680);
  final quinary = Color(0xFFA4A7AE);
  final disabled = Color(0xFFA4A7AE);
}

class Error {
  final primary = Color(0xFFD92D20);
  final secondary = Color(0xFFF04438);
}

class Success {
  final primary = Color(0xFF079455);
  final secondary = Color(0xFF17B26A);
}

class Brand {
  final primary = Color(0xFF7F56D9);
  final secondary = Color(0xFF9E77ED);
}

class ZehnlyBorder {
  final primary = Color(0xFFD5D7DA);
  final secondary = Color(0xFFE9EAEB);
}

class ZehnlyText {
  final primary = Color(0xFF181D27);
  final tertiary = Color(0xFF535862);
  final quaternary = Color(0xFF717680);
  final placeholder = Color(0xFF717680);
  final onPrimary = Color(0xFFFFFFFF);
  final paragraph = Color(0xFF797A7F);
  final white = Color(0xFFFFFFFF);
}

class Background {
  final primary = Color(0xFFFFFFFF);
  final secondary = Color(0xFFFAFAFA);
  final tertiary = Color(0xFFF5F5F5);
  final disabled = Color(0xFFF5F5F5);
}

class Warning {
  final primary = Color(0xFFDC6803);
  final secondary = Color(0xFFF79009);
}

class Flashcards {
  final primary = Color(0xffFFE0BC);
  final secondary = Color(0xffFFEAD3);
  final tertiary = Color(0xffFFF5E9);
}

class ProgressColors {
  final notFilled = Color(0xffFFEAD3);
  final stroke = Color(0xffFFC17A);
}

class Field {
  final focused = Color(0xFFE9EBED);
}

class CardColors {
  final Color whiteBg = IbratColors.white;
  final Color bg = Color(0xffefefef);
  final Color stroke = IbratColors.black10;
  final Color secondaryStroke = IbratColors.black9;
  final Color focusedStroke = IbratColors.main1_15;
  final Color focusedCard = IbratColors.main1_18;
  final Color lightGreen = IbratColors.green2;
  final Color brandColor = IbratColors.main1_17;
  final Color lightBlue = IbratColors.main2_17;
  final Color lightRed = IbratColors.red2;
  final Color lightYellow = IbratColors.yellow3;
  final Color errorStroke = IbratColors.red14;
  final Color errorCard = IbratColors.red10;
  final Color correctCard = IbratColors.green10;
  final Color statusCard = IbratColors.main1_11;
}

class ButtonColors {
  final ButtonType primary;
  final ButtonType secondary;
  final ButtonType tertiary;
  final ButtonType white;
  final ButtonType radio;
  final ButtonType radioAlt;

  const ButtonColors({
    this.primary = const ButtonType(),
    this.secondary = const ButtonType(),
    this.tertiary = const ButtonType(),
    this.white = const ButtonType(),
    this.radio = const ButtonType(),
    this.radioAlt = const ButtonType(),
  });
}

class ButtonType {
  final ButtonState base;
  final ButtonState disabled;
  final ButtonState pressed;
  final ButtonState error;
  final ButtonState success;
  final ButtonState selected;

  const ButtonType({
    this.base = const ButtonState(),
    this.disabled = const ButtonState(),
    ButtonState? pressed,
    this.error = const ButtonState(),
    this.success = const ButtonState(),
    this.selected = const ButtonState(),
  }) : pressed = pressed ?? base;
}

class ButtonState {
  final Color button;
  final Color label;
  final Color border;

  const ButtonState({
    this.button = IbratColors.transparent,
    this.label = IbratColors.transparent,
    this.border = IbratColors.transparent,
  });
}
