import 'package:flutter/material.dart';

class Mode {
  final Color bg;
  final Color whiteBg;
  final ButtonColors buttons;
  final HeaderColors headers;
  final TabColors tabs;
  final FontColors fonts;
  final IconColors icons;
  final ProgressColors progress;
  final CardColors cards;
  final InputColors inputs;
  final Flashcards flashcards;

  Mode.light()
      : bg = IbratColors.backgroundLight,
        whiteBg = IbratColors.white,
        buttons = const ButtonColors(
          primary: ButtonType(
            base: ButtonState(
              button: IbratColors.yellow,
              label: IbratColors.white,
              border: IbratColors.main1_9,
            ),
            disabled: ButtonState(
              button: IbratColors.black10,
              label: IbratColors.black8,
              border: IbratColors.black9,
            ),
            pressed: ButtonState(
              button: IbratColors.yellow,
              label: IbratColors.white,
              border: IbratColors.main1_9,
            ),
          ),
          secondary: ButtonType(
            base: ButtonState(
              button: IbratColors.white,
              label: IbratColors.yellow,
              border: IbratColors.black10,
            ),
            disabled: ButtonState(
              button: IbratColors.black10,
              label: IbratColors.black8,
              border: IbratColors.black10,
            ),
            pressed: ButtonState(
              button: IbratColors.main1_18,
              label: IbratColors.yellow,
              border: IbratColors.black10,
            ),
          ),
          tertiary: ButtonType(
            base: ButtonState(
              label: IbratColors.yellow,
            ),
            pressed: ButtonState(
              label: IbratColors.yellow,
            ),
            disabled: ButtonState(
              label: IbratColors.black8,
            ),
            error: ButtonState(
              label: IbratColors.red10,
            ),
            success: ButtonState(
              label: IbratColors.green10,
            ),
          ),
          white: ButtonType(
            base: ButtonState(
              button: IbratColors.white,
              label: IbratColors.yellow,
              border: IbratColors.black10,
            ),
            pressed: ButtonState(
              button: IbratColors.white,
              label: IbratColors.yellow,
              border: IbratColors.black10,
            ),
            disabled: ButtonState(
              button: IbratColors.black1,
              border: IbratColors.black1,
              label: IbratColors.black5,
            ),
          ),
          radio: ButtonType(
            base: ButtonState(
              button: IbratColors.white,
              label: IbratColors.black1,
              border: IbratColors.black10,
            ),
            disabled: ButtonState(
              button: IbratColors.black10,
              label: IbratColors.black8,
              border: IbratColors.black10,
            ),
            pressed: ButtonState(
              button: IbratColors.main1_18,
              label: IbratColors.yellow,
              border: IbratColors.main1_15,
            ),
            selected: ButtonState(
              button: IbratColors.main1_15,
              label: IbratColors.yellow,
              border: IbratColors.main1_15,
            ),
          ),
          radioAlt: ButtonType(
            base: ButtonState(
              button: IbratColors.white,
              label: IbratColors.black1,
              border: IbratColors.black10,
            ),
            disabled: ButtonState(
              button: IbratColors.black10,
              label: IbratColors.black8,
              border: IbratColors.black10,
            ),
            pressed: ButtonState(
              button: IbratColors.green1,
              label: IbratColors.green10,
              border: IbratColors.green4,
            ),
            selected: ButtonState(
              button: IbratColors.green1,
              label: IbratColors.green10,
              border: IbratColors.green4,
            ),
          ),
        ),
        headers = HeaderColors(bg: IbratColors.yellow),
        tabs = TabColors(
          bg: IbratColors.backgroundLight,
          stroke: IbratColors.black10,
          icon: IbratColors.black6,
          iconSelected: IbratColors.yellow,
          label: IbratColors.black5,
          labelSelected: IbratColors.yellow,
        ),
        fonts = FontColors(
          title: IbratColors.black1,
          subtitle: IbratColors.black3,
          paragraph: IbratColors.black5,
          disabled: IbratColors.black8,
          alert: IbratColors.yellow,
          error: IbratColors.red10,
          info: IbratColors.blue,
          success: IbratColors.green10,
          onPrimary: IbratColors.white,
        ),
        icons = IconColors(
          primary: IbratColors.yellow,
          secondary: IbratColors.black3,
          tertiary: IbratColors.black5,
          red: IbratColors.red10,
          info: IbratColors.blue,
          alert: IbratColors.yellow,
          bg: IbratColors.main1_18,
        ),
        progress = ProgressColors(
          notFilled: IbratColors.main1_17,
          filled: IbratColors.main1_10,
          stroke: IbratColors.main1_13,
          alert: IbratColors.yellow,
          error: IbratColors.red10,
          success: IbratColors.green10,
          info: IbratColors.blue,
        ),
        cards = CardColors(
          whiteBg: IbratColors.white,
          bg: Color(0xffefefef),
          stroke: IbratColors.black10,
          focusedStroke: IbratColors.main1_15,
          focusedCard: IbratColors.main1_18,
          lightGreen: IbratColors.green2,
          brandColor: IbratColors.main1_17,
          lightBlue: IbratColors.main2_17,
          lightRed: IbratColors.red2,
          lightYellow: IbratColors.yellow3,
        ),
        inputs = InputColors(
          inputBg: IbratColors.white,
          activeBg: IbratColors.backgroundLight,
          activeStroke: IbratColors.main2_9,
          stroke: IbratColors.black8,
          errorStroke: const Color(0xFFEE655C),
          successStroke: IbratColors.green10,
        ),
        flashcards = Flashcards(
          primary: IbratColors.main1_16,
          secondary: IbratColors.main1_17,
          tertiary: IbratColors.main1_18,
        );

  Mode.dark()
      : bg = IbratColors.backgroundDark,
        whiteBg = IbratColors.black,
        buttons = const ButtonColors(
          primary: ButtonType(
            base: ButtonState(
              button: IbratColors.blue,
              label: IbratColors.white,
              border: IbratColors.main2_8,
            ),
            disabled: ButtonState(
              button: IbratColors.black1,
              label: IbratColors.black5,
              border: IbratColors.black3,
            ),
            pressed: ButtonState(
              button: IbratColors.blue,
              label: IbratColors.white,
              border: IbratColors.main2_8,
            ),
          ),
          secondary: ButtonType(
            base: ButtonState(
              button: IbratColors.backgroundDark,
              label: IbratColors.blue,
              border: IbratColors.black,
            ),
            disabled: ButtonState(
              button: IbratColors.black1,
              border: IbratColors.black1,
              label: IbratColors.black5,
            ),
            pressed: ButtonState(
              button: IbratColors.main2_1,
              label: IbratColors.white,
              border: IbratColors.black,
            ),
          ),
          tertiary: ButtonType(
            base: ButtonState(
              label: IbratColors.blue,
            ),
            disabled: ButtonState(
              label: IbratColors.black5,
            ),
            error: ButtonState(
              label: IbratColors.red10,
            ),
            success: ButtonState(
              label: IbratColors.green10,
            ),
            pressed: ButtonState(
              label: IbratColors.blue,
            ),
          ),
          white: ButtonType(
            base: ButtonState(
              button: IbratColors.white,
              label: IbratColors.yellow,
              border: IbratColors.black10,
            ),
            pressed: ButtonState(
              button: IbratColors.white,
              label: IbratColors.yellow,
              border: IbratColors.black10,
            ),
            disabled: ButtonState(
              button: IbratColors.black1,
              border: IbratColors.black3,
              label: IbratColors.black5,
            ),
          ),
          radio: ButtonType(
            base: ButtonState(
              button: IbratColors.backgroundDark,
              label: IbratColors.white,
              border: IbratColors.black2,
            ),
            disabled: ButtonState(
              button: IbratColors.black1,
              border: IbratColors.black1,
              label: IbratColors.black5,
            ),
            pressed: ButtonState(
              button: IbratColors.main2_1,
              label: IbratColors.blue,
              border: IbratColors.main2_12,
            ),
            selected: ButtonState(
              button: IbratColors.main2_1,
              label: IbratColors.blue,
              border: IbratColors.main2_8,
            ),
          ),
          radioAlt: ButtonType(
            base: ButtonState(
              button: IbratColors.white,
              label: IbratColors.black1,
              border: IbratColors.black10,
            ),
            disabled: ButtonState(
              button: IbratColors.black10,
              label: IbratColors.black8,
              border: IbratColors.black10,
            ),
            pressed: ButtonState(
              button: IbratColors.green1,
              label: IbratColors.green10,
              border: IbratColors.green4,
            ),
            selected: ButtonState(
              button: IbratColors.green1,
              label: IbratColors.green10,
              border: IbratColors.green4,
            ),
          ),
        ),
        headers = HeaderColors(bg: IbratColors.main2_2),
        tabs = TabColors(
          bg: IbratColors.backgroundDark,
          stroke: IbratColors.black1,
          icon: IbratColors.black6,
          iconSelected: IbratColors.main2_10,
          label: IbratColors.black8,
          labelSelected: IbratColors.main2_14,
        ),
        fonts = FontColors(
          title: IbratColors.white,
          subtitle: IbratColors.black9,
          paragraph: IbratColors.black7,
          disabled: IbratColors.black3,
          alert: IbratColors.yellow,
          error: IbratColors.red10,
          info: IbratColors.blue,
          success: IbratColors.green10,
          onPrimary: IbratColors.white,
        ),
        icons = IconColors(
          primary: IbratColors.blue,
          secondary: IbratColors.black9,
          tertiary: IbratColors.black7,
          red: IbratColors.red10,
          info: IbratColors.blue,
          alert: IbratColors.yellow,
          bg: IbratColors.main2_1,
        ),
        progress = ProgressColors(
          notFilled: IbratColors.main2_2,
          filled: IbratColors.main2_9,
          stroke: IbratColors.main2_12,
          alert: IbratColors.yellow,
          error: IbratColors.red10,
          success: IbratColors.green10,
          info: IbratColors.blue,
        ),
        cards = CardColors(
          whiteBg: IbratColors.black,
          bg: IbratColors.main2_1,
          stroke: IbratColors.black2,
          focusedStroke: IbratColors.main2_5,
          focusedCard: IbratColors.main2_1,
          lightGreen: IbratColors.green18,
          brandColor: IbratColors.main1_1,
          lightBlue: IbratColors.main2_1,
          lightRed: IbratColors.red18,
          lightYellow: IbratColors.yellow18,
          statusCard: IbratColors.main2_11,
        ),
        inputs = InputColors(
          inputBg: IbratColors.black1,
          activeBg: IbratColors.backgroundDark,
          activeStroke: IbratColors.main2_9,
          stroke: IbratColors.black2,
          errorStroke: const Color(0xFFEE655C),
          successStroke: IbratColors.green10,
        ),
        flashcards = Flashcards(
          primary: IbratColors.main2_1,
          secondary: IbratColors.main2_2,
          tertiary: IbratColors.main2_3,
        );
}

class InputColors {
  final Color inputBg;
  final Color activeBg;
  final Color activeStroke;
  final Color stroke;
  final Color errorStroke;
  final Color successStroke;

  InputColors({
    required this.inputBg,
    required this.activeBg,
    required this.activeStroke,
    required this.stroke,
    required this.errorStroke,
    required this.successStroke,
  });
}

class Flashcards {
  final Color primary;
  final Color secondary;
  final Color tertiary;

  Flashcards({
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });
}

class CardColors {
  final Color whiteBg;
  final Color bg;
  final Color stroke;
  final Color focusedStroke;
  final Color focusedCard;
  final Color lightGreen;
  final Color brandColor;
  final Color lightBlue;
  final Color lightRed;
  final Color lightYellow;
  final Color errorStroke;
  final Color errorCard;
  final Color correctCard;
  final Color statusCard;

  CardColors({
    required this.whiteBg,
    required this.bg,
    required this.stroke,
    required this.focusedStroke,
    required this.focusedCard,
    required this.lightGreen,
    required this.brandColor,
    required this.lightBlue,
    required this.lightRed,
    required this.lightYellow,
    this.errorStroke = IbratColors.red14,
    this.errorCard = IbratColors.red10,
    this.correctCard = IbratColors.green10,
    this.statusCard = IbratColors.main1_11,
  });
}

class ProgressColors {
  final Color notFilled;
  final Color filled;
  final Color stroke;
  final Color alert;
  final Color error;
  final Color success;
  final Color info;

  ProgressColors({
    required this.notFilled,
    required this.filled,
    required this.stroke,
    required this.alert,
    required this.error,
    required this.success,
    required this.info,
  });
}

class IconColors {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color red;
  final Color info;
  final Color alert;
  final Color bg;
  final Color green;

  IconColors({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.red,
    required this.info,
    required this.alert,
    required this.bg,
    this.green = IbratColors.green10,
  });
}

class FontColors {
  final Color title;
  final Color subtitle;
  final Color paragraph;
  final Color disabled;
  final Color alert;
  final Color error;
  final Color info;
  final Color success;
  final Color onPrimary;

  FontColors({
    required this.title,
    required this.subtitle,
    required this.paragraph,
    required this.disabled,
    required this.alert,
    required this.error,
    required this.info,
    required this.success,
    required this.onPrimary,
  });
}

class TabColors {
  final Color bg;
  final Color stroke;
  final Color icon;
  final Color iconSelected;
  final Color label;
  final Color labelSelected;

  TabColors({
    required this.bg,
    required this.stroke,
    required this.icon,
    required this.iconSelected,
    required this.label,
    required this.labelSelected,
  });
}

class HeaderColors {
  final Color bg;

  HeaderColors({required this.bg});
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
    this.pressed = const ButtonState(),
    this.error = const ButtonState(),
    this.success = const ButtonState(),
    this.selected = const ButtonState(),
  });
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

class IbratColors {
  static const Color backgroundDark = Color(0xff091621);
  static const Color backgroundLight = Color(0xffFAFAFA);
  static const Color black = Color(0xff1F222A);
  static const Color black1 = Color(0xff1F222A);
  static const Color black10 = Color(0xffE9E9EA);
  static const Color black2 = Color(0xff35383F);
  static const Color black3 = Color(0xff4C4E55);
  static const Color black4 = Color(0xff62646A);
  static const Color black5 = Color(0xff797A7F);
  static const Color black6 = Color(0xff8F9195);
  static const Color black7 = Color(0xffA5A7AA);
  static const Color black8 = Color(0xffBCBDBF);
  static const Color black9 = Color(0xffD2D3D4);
  static const Color blue = Color(0xff3F9CFB);
  static const Color green1 = Color(0xffEEFAF3);
  static const Color green10 = Color(0xff54CF85);
  static const Color green11 = Color(0xff4CBA78);
  static const Color green12 = Color(0xff43A66A);
  static const Color green13 = Color(0xff3B915D);
  static const Color green14 = Color(0xff327C50);
  static const Color green15 = Color(0xff2A6843);
  static const Color green16 = Color(0xff225335);
  static const Color green17 = Color(0xff193E28);
  static const Color green18 = Color(0xff11291B);
  static const Color green2 = Color(0xffDDF5E7);
  static const Color green3 = Color(0xffCCF1DA);
  static const Color green4 = Color(0xffBBECCE);
  static const Color green5 = Color(0xffAAE7C2);
  static const Color green6 = Color(0xff98E2B6);
  static const Color green7 = Color(0xff87DDAA);
  static const Color green8 = Color(0xff76D99D);
  static const Color green9 = Color(0xff65D491);
  static const Color main1_1 = Color(0xff331E07);
  static const Color main1_10 = Color(0xffFFA137);
  static const Color main1_11 = Color(0xffFFAC4D);
  static const Color main1_12 = Color(0xffFFB664);
  static const Color main1_13 = Color(0xffFFC17A);
  static const Color main1_14 = Color(0xffFFCB90);
  static const Color main1_15 = Color(0xffFFD5A6);
  static const Color main1_16 = Color(0xffFFE0BC);
  static const Color main1_17 = Color(0xffFFEAD3);
  static const Color main1_18 = Color(0xffFFF5E9);
  static const Color main1_2 = Color(0xff4C2D0A);
  static const Color main1_3 = Color(0xff663C0D);
  static const Color main1_4 = Color(0xff804C11);
  static const Color main1_5 = Color(0xff995B14);
  static const Color main1_6 = Color(0xffB36A17);
  static const Color main1_7 = Color(0xffCC791A);
  static const Color main1_8 = Color(0xffE6881E);
  static const Color main1_9 = Color(0xffFF8500);
  static const Color main2_1 = Color(0xff0D1F32);
  static const Color main2_10 = Color(0xff52A6FB);
  static const Color main2_11 = Color(0xff65B0FC);
  static const Color main2_12 = Color(0xff79BAFC);
  static const Color main2_13 = Color(0xff8CC4FD);
  static const Color main2_14 = Color(0xff9FCEFD);
  static const Color main2_15 = Color(0xffB2D7FD);
  static const Color main2_16 = Color(0xffC5E1FE);
  static const Color main2_17 = Color(0xffD9EBFE);
  static const Color main2_18 = Color(0xffECF5FF);
  static const Color main2_2 = Color(0xff132F4B);
  static const Color main2_3 = Color(0xff193E64);
  static const Color main2_4 = Color(0xff204E7E);
  static const Color main2_5 = Color(0xff265E97);
  static const Color main2_6 = Color(0xff2C6DB0);
  static const Color main2_7 = Color(0xff327DC9);
  static const Color main2_8 = Color(0xff398CE2);
  static const Color main2_9 = Color(0xff3F9CFB);
  static const Color red1 = Color(0xffFDF0EF);
  static const Color red10 = Color(0xffEE655C);
  static const Color red11 = Color(0xffD65B53);
  static const Color red12 = Color(0xffBE514A);
  static const Color red13 = Color(0xffA74740);
  static const Color red14 = Color(0xff8F3D37);
  static const Color red15 = Color(0xff77332E);
  static const Color red16 = Color(0xff5F2825);
  static const Color red17 = Color(0xff471E1C);
  static const Color red18 = Color(0xff301412);
  static const Color red2 = Color(0xffFCE0DE);
  static const Color red3 = Color(0xffFAD1CE);
  static const Color red4 = Color(0xffF8C1BE);
  static const Color red5 = Color(0xffF7B2AE);
  static const Color red6 = Color(0xffF5A39D);
  static const Color red7 = Color(0xffF3938D);
  static const Color red8 = Color(0xffF1847D);
  static const Color red9 = Color(0xffF0746C);
  static const Color white = Color(0xffFFFFFF);
  static const Color yellow = Color(0xffFF9721);
  static const Color yellow1 = Color(0xffFFFDE6);
  static const Color yellow10 = Color(0xffFFEE00);
  static const Color yellow11 = Color(0xffE6D600);
  static const Color yellow12 = Color(0xffCCBE00);
  static const Color yellow13 = Color(0xffB3A700);
  static const Color yellow14 = Color(0xff998F00);
  static const Color yellow15 = Color(0xff807700);
  static const Color yellow16 = Color(0xff665F00);
  static const Color yellow17 = Color(0xff4C4700);
  static const Color yellow18 = Color(0xff272501);
  static const Color yellow2 = Color(0xffFFFCCC);
  static const Color yellow3 = Color(0xffFFFAB3);
  static const Color yellow4 = Color(0xffFFF899);
  static const Color yellow5 = Color(0xffFFF780);
  static const Color yellow6 = Color(0xffFFF566);
  static const Color yellow7 = Color(0xffFFF34D);
  static const Color yellow8 = Color(0xffFFF133);
  static const Color yellow9 = Color(0xffFFF01A);
  static const Color transparent = Color(0x00000000);
}
