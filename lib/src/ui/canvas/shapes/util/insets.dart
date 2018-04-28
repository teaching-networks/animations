/**
 * Insets which can be used a padding, margin, etc.
 */
class Insets {
  static const double DEFAULT_INSET = 0.0;
  static const double MIN_INSET = 0.0;

  final double top;
  final double left;
  final double bottom;
  final double right;

  const Insets({double top = DEFAULT_INSET, double left = DEFAULT_INSET, double bottom = DEFAULT_INSET, double right = DEFAULT_INSET})
      : this.top = (top >= MIN_INSET ? top : MIN_INSET),
        this.left = (left >= MIN_INSET ? left : MIN_INSET),
        this.bottom = (bottom >= MIN_INSET ? bottom : MIN_INSET),
        this.right = (right >= MIN_INSET ? right : MIN_INSET);
}
