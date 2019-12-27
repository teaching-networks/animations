/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/shapes/util/edges.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

/// Style of a round rectangle.
class RoundRectStyle {
  /// Edge roundness settings.
  final Edges edges;

  /// Color of the fill (or null if transparent).
  final Color fillColor;

  /// Color of the border (or null if transparent).
  final Color borderColor;

  /// Thickness of the border.
  final double borderThickness;

  /// Padding of the container.
  final double padding;

  /// Create round rectangle style.
  const RoundRectStyle({
    this.edges = const Edges.all(0),
    this.fillColor = Colors.WHITE,
    this.borderColor = null,
    this.borderThickness = 0,
    this.padding = 0,
  });

  /// Check if the rect has a border per style definition.
  bool get hasBorder => borderColor != null && borderThickness > 0;

  /// Whether the rect has a fill per style definition.
  bool get hasFill => fillColor != null;

  /// Whether the rect has round edges.
  bool get isRound => edges != null && (edges.bottomLeft > 0 || edges.bottomRight > 0 || edges.topLeft > 0 || edges.topRight > 0);
}
