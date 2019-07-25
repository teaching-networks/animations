import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/animations/shared/generator/cloud_generator/cloud_generator.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/anim/anim.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/canvas_context_util.dart';
import 'package:hm_animations/src/ui/canvas/image/alignment/image_alignment.dart';
import 'package:hm_animations/src/ui/misc/image/image_info.dart';

/// Mixin providing reusable functionality within onion router scenario drawables.
mixin ScenarioDrawable {
  /// How many relay nodes to display.
  static const int _relayNodeCount = 20;

  /// Generate the relay nodes to show.
  Future<List<Point<double>>> generateRelayNodes({
    int nodeCount = _relayNodeCount,
  }) async {
    return CloudGenerator.generate(_relayNodeCount, minDistance: 0.2);
  }

  /// Draw nodes on the given [drawable] with the given [img].
  void drawNodes(
    Drawable drawable,
    Rectangle<double> rectangle,
    List<Point<double>> nodeCoordinates, // Coordinates of the nodes to draw (relative from 0.0 to 1.0)
    CanvasImageSource img, // Image to draw as representation of the nodes
    ImageInfo imgInfo, {
    List<Point<double>> coordinates, // Real coordinates of the drawn nodes
    List<Rectangle<double>> bounds, // Real bounds of the drawn nodes
    List<int> indicesToHighlight, // Node indices to highlight
    List<int> oldIndicesToHighlight, // Used to animate the indices to highlight change
    Anim highlightAnimation,
    Map<int, NodeHighlightOptions> highlightOptions = const {},
  }) {
    if (nodeCoordinates == null || img == null) {
      return;
    }

    if (coordinates == null) coordinates = List<Point<double>>();
    if (bounds == null) bounds = List<Rectangle<double>>();

    double iW = rectangle.width * 0.1;
    double iH = rectangle.height * 0.1;
    double xPad = rectangle.width * 0.1;
    double yPad = rectangle.height * 0.1;
    double x = rectangle.left + xPad;
    double y = rectangle.top + yPad;
    double w = rectangle.width - xPad * 2;
    double h = rectangle.height - yPad * 2;

    // Layout relay nodes first -> Calculate current coordinates on the canvas
    coordinates.clear();
    bounds.clear();

    for (int i = 0; i < nodeCoordinates.length; i++) {
      Point<double> point = nodeCoordinates[i];

      Rectangle<double> b = drawable.layoutImage(
        width: iW,
        height: iH,
        aspectRatio: imgInfo.aspectRatio,
        x: x + point.x * w - iW / 2,
        y: y + point.y * h - iH / 2,
        mode: ImageDrawMode.FILL,
        alignment: ImageAlignment.MID,
      );

      bounds.add(b);
      coordinates.add(Point<double>(b.left + b.width / 2, b.top + b.height / 2));
    }

    final routeIndicesLookup = indicesToHighlight != null ? indicesToHighlight.toSet() : null;
    final oldRouteIndicesLookup = oldIndicesToHighlight != null && oldIndicesToHighlight.isNotEmpty ? oldIndicesToHighlight.toSet() : null;

    // Draw background relay nodes
    drawable.ctx.save();
    drawable.ctx.globalAlpha = 0.5;

    for (int i = 0; i < nodeCoordinates.length; i++) {
      if ((routeIndicesLookup != null && routeIndicesLookup.contains(i)) ||
          (highlightAnimation != null && highlightAnimation.running && oldRouteIndicesLookup != null && oldRouteIndicesLookup.contains(i))) {
        continue;
      }

      drawable.ctx.drawImageToRect(
        img,
        bounds[i],
      );
    }

    drawable.ctx.restore();

    if (indicesToHighlight != null) {
      if (highlightAnimation != null && highlightAnimation.running) {
        // Reduce indices which are already highlighted
        Set<int> sameIndices = Set<int>();
        Set<int> growIndices = Set.of(indicesToHighlight);
        Set<int> shrinkIndices = oldIndicesToHighlight != null ? Set.of(oldIndicesToHighlight) : Set<int>();
        if (indicesToHighlight != null && oldIndicesToHighlight != null && oldIndicesToHighlight.isNotEmpty) {
          for (int index in indicesToHighlight) {
            if (oldIndicesToHighlight.contains(index)) {
              sameIndices.add(index);
              growIndices.remove(index);
              shrinkIndices.remove(index);
            }
          }
        }

        if (sameIndices.isNotEmpty) {
          for (int i in sameIndices) {
            Point<double> point = nodeCoordinates[i];

            final imageInfo = highlightOptions[i]?.replacementImageInfo ?? imgInfo;

            final newBounds = drawable.layoutImage(
              width: iW * 2,
              height: iH * 2,
              aspectRatio: imageInfo.aspectRatio,
              x: x + point.x * w - iW,
              y: y + point.y * h - iH,
              mode: ImageDrawMode.FILL,
              alignment: ImageAlignment.MID,
            );

            bounds[i] = newBounds;

            drawable.ctx.drawImageToRect(
              imageInfo.image,
              newBounds,
            );
          }
        }

        if (shrinkIndices.isNotEmpty) {
          double reverseProgress = 1.0 - highlightAnimation.progress;

          // Draw old chosen nodes of the route
          double shrinkWidth = iW + iW * reverseProgress;
          double shrinkHeight = iW + iH * reverseProgress;

          drawable.ctx.save();
          drawable.ctx.globalAlpha = 0.5 + 0.5 * reverseProgress;

          for (int i in shrinkIndices) {
            Point<double> point = nodeCoordinates[i];

            final newBounds = drawable.layoutImage(
              width: shrinkWidth,
              height: shrinkHeight,
              aspectRatio: imgInfo.aspectRatio,
              x: x + point.x * w - shrinkWidth / 2,
              y: y + point.y * h - shrinkHeight / 2,
              mode: ImageDrawMode.FILL,
              alignment: ImageAlignment.MID,
            );

            bounds[i] = newBounds;

            drawable.ctx.drawImageToRect(
              img,
              newBounds,
            );
          }

          drawable.ctx.restore();
        }

        // Draw new route nodes
        double growWidth = iW + iW * highlightAnimation.progress;
        double growHeight = iH + iH * highlightAnimation.progress;

        drawable.ctx.save();
        drawable.ctx.globalAlpha = 0.5 + 0.5 * highlightAnimation.progress;

        for (int i in growIndices) {
          Point<double> point = nodeCoordinates[i];

          final imageInfo = highlightOptions[i]?.replacementImageInfo ?? imgInfo;

          final newBounds = drawable.layoutImage(
            width: growWidth,
            height: growHeight,
            aspectRatio: imageInfo.aspectRatio,
            x: x + point.x * w - growWidth / 2,
            y: y + point.y * h - growHeight / 2,
            mode: ImageDrawMode.FILL,
            alignment: ImageAlignment.MID,
          );

          bounds[i] = newBounds;

          drawable.ctx.drawImageToRect(
            imageInfo.image,
            newBounds,
          );
        }

        drawable.ctx.restore();
      } else {
        // Draw chosen nodes of the route
        for (int i in indicesToHighlight) {
          Point<double> point = nodeCoordinates[i];

          final imageInfo = highlightOptions[i]?.replacementImageInfo ?? imgInfo;

          final newBounds = drawable.layoutImage(
            width: iW * 2,
            height: iH * 2,
            aspectRatio: imageInfo.aspectRatio,
            x: x + point.x * w - iW,
            y: y + point.y * h - iH,
            mode: ImageDrawMode.FILL,
            alignment: ImageAlignment.MID,
          );

          bounds[i] = newBounds;

          drawable.ctx.drawImageToRect(
            imageInfo.image,
            newBounds,
          );
        }
      }
    }
  }
}

/// Options for highlighting nodes.
class NodeHighlightOptions {
  /// Image info for the replacement image.
  /// Will replace the default image.
  final ImageInfo replacementImageInfo;

  /// Create highlight options for a node.
  NodeHighlightOptions({
    this.replacementImageInfo,
  });
}
