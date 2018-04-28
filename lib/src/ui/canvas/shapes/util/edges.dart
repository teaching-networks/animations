import 'dart:math';
import 'package:netzwerke_animationen/src/util/size.dart';

/**
 * Edges usable for radius info.
 */
class Edges {
  static const double DEFAULT_RADIUS = 0.0;
  static const double MIN_RADIUS = 0.0;

  final double topLeft;
  final double topRight;
  final double bottomLeft;
  final double bottomRight;

  const Edges({double topLeft = DEFAULT_RADIUS, double topRight = DEFAULT_RADIUS, double bottomLeft = DEFAULT_RADIUS, double bottomRight = DEFAULT_RADIUS})
      : this.topLeft = (topLeft >= MIN_RADIUS ? topLeft : MIN_RADIUS),
        this.topRight = (topRight >= MIN_RADIUS ? topRight : MIN_RADIUS),
        this.bottomLeft = (bottomLeft >= MIN_RADIUS ? bottomLeft : MIN_RADIUS),
        this.bottomRight = (bottomRight >= MIN_RADIUS ? bottomRight : MIN_RADIUS);

  const Edges.all(double radius) : this(topLeft: radius, topRight: radius, bottomLeft: radius, bottomRight: radius);

  /**
   * Convert edges (given in percent with range [0.0, 1.0]) using the passed size to pixel sizes.
   */
  static Edges convertPercent(Edges edges, Size size) {
    double ref = min(size.width, size.height);
    double maxRadius = ref / 2;

    return new Edges(
        topLeft: min(edges.topLeft * ref, maxRadius),
        topRight: min(edges.topRight * ref, maxRadius),
        bottomLeft: min(edges.bottomLeft * ref, maxRadius),
        bottomRight: min(edges.bottomRight * ref, maxRadius));
  }
}
