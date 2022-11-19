

import 'dart:ui';

Paint fromColor(Color color) {
  return Paint()
    ..color = color
    ..strokeWidth = 6
    ..isAntiAlias = true
    ..style = PaintingStyle.fill
    ..blendMode = BlendMode.plus;
}