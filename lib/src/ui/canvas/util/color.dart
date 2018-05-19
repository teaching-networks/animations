/**
 * Color utility class.
 */
class Color {

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
  const Color.hex(int number) : blue = (number & BYTE_MASK), green = ((number >> 8) & BYTE_MASK), red = ((number >> 16) & BYTE_MASK), alpha = ((number >> 24) & BYTE_MASK) / BYTE_MASK;

  /**
   * Create new color with red [0; 255], green [0; 255], blue [0; 255] and alpha [0.0; 1.0] values.
   */
  const Color.rgba(this.red, this.green, this.blue, this.alpha);

  static Color opacity(Color color, double alpha) {
    return new Color.rgba(color.red, color.green, color.blue, alpha);
  }

}