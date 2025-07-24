import 'package:flutter/cupertino.dart';

extension StringToTextExtensions on String? {
  Text title1(BuildContext context) =>
      Text(this ?? '', style: TextStyles.title1(context));

  Text title2(BuildContext context) =>
      Text(this ?? '', style: TextStyles.title2(context));

  Text title3(BuildContext context) =>
      Text(this ?? '', style: TextStyles.title3(context));

  Text title4(BuildContext context) =>
      Text(this ?? '', style: TextStyles.title4(context));

  Text subtitle1(BuildContext context) =>
      Text(this ?? '', style: TextStyles.subtitle1(context));

  Text subtitle2(BuildContext context) =>
      Text(this ?? '', style: TextStyles.subtitle2(context));

  Text subtitle3(BuildContext context) =>
      Text(this ?? '', style: TextStyles.subtitle3(context));

  Text subtitle4(BuildContext context) =>
      Text(this ?? '', style: TextStyles.subtitle4(context));

  Text subtitle5(BuildContext context) =>
      Text(this ?? '', style: TextStyles.subtitle5(context));

  Text body1(BuildContext context) =>
      Text(this ?? '', style: TextStyles.body1(context));

  Text body2(BuildContext context) =>
      Text(this ?? '', style: TextStyles.body2(context));

  Text body3(BuildContext context) =>
      Text(this ?? '', style: TextStyles.body3(context));

  Text body4(BuildContext context) =>
      Text(this ?? '', style: TextStyles.body4(context));

  Text body5(BuildContext context) =>
      Text(this ?? '', style: TextStyles.body5(context));

  Text body6(BuildContext context) =>
      Text(this ?? '', style: TextStyles.body6(context));

  Text large(BuildContext context) =>
      Text(this ?? '', style: TextStyles.large(context));

  Text medium(BuildContext context) =>
      Text(this ?? '', style: TextStyles.medium(context));

  Text small(BuildContext context) =>
      Text(this ?? '', style: TextStyles.small(context));
}

abstract class TextStyles {
  static TextStyle title1(BuildContext context) => TextStyle(
        fontSize: 32,
        height: 40 / 32,
        fontWeight: FontWeight.w800,
        // color: context.theme.fonts.title,
      );

  static TextStyle title2(BuildContext context) =>
      title1(context).copyWith(fontSize: 28, height: 36 / 28);

  static TextStyle title3(BuildContext context) =>
      title1(context).copyWith(fontSize: 24, height: 32 / 24);

  static TextStyle title4(BuildContext context) =>
      title1(context).copyWith(fontSize: 20, height: 28 / 20);

  static TextStyle subtitle1(BuildContext context) => TextStyle(
        fontSize: 22,
        height: 30 / 22,
        fontWeight: FontWeight.w700,
        // color: context.theme.fonts.title,
      );

  static TextStyle subtitle2(BuildContext context) =>
      subtitle1(context).copyWith(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle subtitle3(BuildContext context) =>
      subtitle1(context).copyWith(
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w500,
      );

  static TextStyle subtitle4(BuildContext context) =>
      subtitle3(context).copyWith(
        fontWeight: FontWeight.w700,
      );

  static TextStyle subtitle5(BuildContext context) =>
      subtitle2(context).copyWith(
        fontWeight: FontWeight.w700,
      );

  static TextStyle body1(BuildContext context) => TextStyle(
        fontSize: 16,
        height: 24 / 16,
        letterSpacing: 16 * 0.15 / 100,
        fontWeight: FontWeight.w500,
        // color: context.theme.fonts.subtitle,
      );

  static TextStyle body2(BuildContext context) =>
      body1(context).copyWith(fontWeight: FontWeight.w700);

  static TextStyle body3(BuildContext context) =>
      body1(context).copyWith(fontWeight: FontWeight.w400);

  static TextStyle body4(BuildContext context) => body1(context).copyWith(
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 14 * 0.1 / 100,
        fontWeight: FontWeight.w500,
      );

  static TextStyle body5(BuildContext context) =>
      body4(context).copyWith(fontWeight: FontWeight.w700);

  static TextStyle body6(BuildContext context) => body4(context).copyWith(
        fontSize: 12,
        height: 18 / 12,
        letterSpacing: 14 * 0.5 / 100,
        fontWeight: FontWeight.w500,
      );

  static TextStyle large(BuildContext context) => TextStyle(
        fontSize: 20,
        height: 24 / 20,
        letterSpacing: 20 / 100,
        fontWeight: FontWeight.w700,
        // color: context.theme.fonts.subtitle,
      );

  static TextStyle medium(BuildContext context) => large(context).copyWith(
        fontSize: 16,
        height: 24 / 16,
        letterSpacing: 16 / 100,
      );

  static TextStyle small(BuildContext context) => large(context).copyWith(
        fontSize: 14,
        height: 24 / 14,
        letterSpacing: 14 / 100,
      );
}
