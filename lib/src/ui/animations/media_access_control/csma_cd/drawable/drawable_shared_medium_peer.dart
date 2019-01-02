import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/peer/shared_medium_peer.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/edges.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/size_type.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:meta/meta.dart';

/// A Drawable shared medium peer.
class DrawableSharedMediumPeer extends CanvasDrawable {
  /// Id of the peer.
  final int id;

  /// Peer to draw.
  final SharedMediumPeer peer;

  /// Round rectangle as background for the peer.
  final RoundRectangle _roundRectangle = RoundRectangle(
    color: Colors.SLATE_GREY,
    radiusSizeType: SizeType.PERCENT,
    paintMode: PaintMode.FILL,
    radius: Edges.all(1.0),
  );

  /// Create drawable peer.
  DrawableSharedMediumPeer({
    @required this.id,
    @required this.peer,
  });

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();

    context.translate(rect.left, rect.top);

    context.textAlign = "center";
    context.textBaseline = "middle";
    context.font = "${rect.height * 0.6}px 'Raleway'";

    _roundRectangle.render(
        context,
        Rectangle(
          0,
          0,
          rect.width,
          rect.height,
        ));

    setFillColor(context, Colors.WHITE);
    context.fillText(id.toString(), rect.width / 2, rect.height / 2);

    context.restore();
  }
}
