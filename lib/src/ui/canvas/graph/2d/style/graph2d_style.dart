import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

/// Style of a Graph2D component displayable in a Graph2D.
class Graph2DStyle {
  /// [color] of the Graph2D component.
  final Color color;

  /// Whether to fill the area below the Graph2D component line.
  final bool fillArea;

  /// The join type of the line.
  final String lineJoin;

  /// Line cap type.
  final String lineCap;

  const Graph2DStyle({Color color = Colors.SLATE_GREY, bool fillArea = false, String lineJoin = "round", String lineCap = "round"})
      : this.color = color,
        this.fillArea = fillArea,
        this.lineJoin = lineJoin,
        this.lineCap = lineCap;
}
