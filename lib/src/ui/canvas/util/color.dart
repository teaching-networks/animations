/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:math';

/**
 * Color utility class.
 */
class Color {
  /// Random number generator for random color constructor.
  static Random rng = new Random();

  /**
   * Mask used to extract color components from number.
   */
  static const int BYTE_MASK = 0xFF;

  final int red;
  final int green;
  final int blue;
  final double alpha;

  /**
   * Create new color with red [0; 255], green [0; 255], blue [0; 255] values.
   */
  const Color.rgb(int red, int green, int blue) : this.rgba(red, green, blue, 1.0);

  /**
   * Create new color from hex number in the form 0x[Alpha][Red][Green][Blue].
   * EXAMPLE:
   * - Color red with 0.5 alpha is: 0x80FF0000 where 80 is 0.5, FF is 255 for red, green and blue are both 0.
   */
  const Color.hex(int number)
      : blue = (number & BYTE_MASK),
        green = ((number >> 8) & BYTE_MASK),
        red = ((number >> 16) & BYTE_MASK),
        alpha = ((number >> 24) & BYTE_MASK) / BYTE_MASK;

  /**
   * Create new color with red [0; 255], green [0; 255], blue [0; 255] and alpha [0.0; 1.0] values.
   */
  const Color.rgba(this.red, this.green, this.blue, this.alpha);

  /// Create new random color.
  Color.random()
      : red = rng.nextInt(255),
        green = rng.nextInt(255),
        blue = rng.nextInt(255),
        alpha = 1.0;

  static Color opacity(Color color, double alpha) {
    return new Color.rgba(color.red, color.green, color.blue, alpha);
  }

  /// Brighten the passed [color] by the given [amount].
  /// When [amount] is 1.0 the resulting color will be completely white.
  static Color brighten(Color color, double amount) {
    int red = ((color.red * (1.0 - amount) / 255 + amount) * 255).toInt();
    int green = ((color.green * (1.0 - amount) / 255 + amount) * 255).toInt();
    int blue = ((color.blue * (1.0 - amount) / 255 + amount) * 255).toInt();

    return Color.rgb(red, green, blue);
  }

  /// Merge two colors [c1] and [c2] and mix them using the passed [threshold].
  /// [threshold] is in range [0.0; 1.0] and defines the strength of the color [c1].
  /// If [threshold] is 1.0, the result will be the first color [c1]. If you pass 0.0 as [threshold]
  /// the result will be [c2].
  static Color merge(Color c1, Color c2, double threshold) {
    if (threshold < 0.0 || threshold > 1.0) {
      throw new Exception("threshold needs to be in range [0.0; 1.0]");
    }

    double t1 = 1.0 - threshold;
    double t2 = threshold;

    int red = (c1.red * t1 + c2.red * t2).round();
    int green = (c1.green * t1 + c2.green * t2).round();
    int blue = (c1.blue * t1 + c2.blue * t2).round();
    double alpha = (c1.alpha * t1 + c2.alpha * t2);

    return Color.rgba(red, green, blue, alpha);
  }

  String toCSSColorString() => "rgba(${red},${green},${blue},${alpha})";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Color && runtimeType == other.runtimeType && red == other.red && green == other.green && blue == other.blue && alpha == other.alpha;

  @override
  int get hashCode => red.hashCode ^ green.hashCode ^ blue.hashCode ^ alpha.hashCode;
}
