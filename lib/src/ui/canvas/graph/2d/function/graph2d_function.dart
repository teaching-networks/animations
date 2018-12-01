import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:meta/meta.dart';

/// The "real" function.
typedef num ValueProcessor(num x);

/// Function displayable in a Graph2D.
class Graph2DFunction {
  /// [processor] is calculating the y values by a x value.
  final ValueProcessor processor;

  /// [style] of the graph (color, etc.).
  final Graph2DFunctionStyle style;

  const Graph2DFunction({@required ValueProcessor processor, Graph2DFunctionStyle style = const Graph2DFunctionStyle()})
      : this.processor = processor,
        this.style = style;
}

/// Style of a function displayable in a Graph2D.
class Graph2DFunctionStyle {
  /// [color] of the function.
  final Color color;

  /// Whether to fill the area below the function line.
  final bool fillArea;

  const Graph2DFunctionStyle({Color color = Colors.SLATE_GREY, bool fillArea = false})
      : this.color = color,
        this.fillArea = fillArea;
}
