import 'dart:ui';

extension ColorX on Color {
  ColorFilter get srcIn => ColorFilter.mode(this, BlendMode.srcIn);
}
