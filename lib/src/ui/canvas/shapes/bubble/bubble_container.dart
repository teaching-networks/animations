/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/edges.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/size_type.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/util/size.dart';
import 'package:meta/meta.dart';

/// Bubble which is able to contain any drawable.
class BubbleContainer extends Drawable {
  /// Default padding.
  static const double _defaultPadding = 10.0;

  /// Arrow height.
  static const double _defaultArrowHeight = 20.0;

  /// Drawable to embed into the bubble.
  final Drawable _drawable;

  /// Background color of the bubble.
  Color _color = Colors.BLACK;

  /// Padding of the bubble.
  double _padding = _defaultPadding;

  /// "real" padding, which is scaled to fit the device pixel ratio.
  double _scaledPadding = _defaultPadding * window.devicePixelRatio;

  /// Height of the arrow.
  double _arrowHeight = _defaultArrowHeight;

  /// "real" height of an arrow, which is scaled to fit the device pixel ratio.
  double _scaledArrowHeight = _defaultArrowHeight * window.devicePixelRatio;

  VerticalArrowOrientation _verticalArrowOrientation;
  HorizontalArrowOrientation _horizontalArrowOrientation;

  double _horizontalFreeDiff;

  RoundRectangle _roundRect = RoundRectangle(
    color: Colors.BLACK,
    paintMode: PaintMode.FILL,
    radius: Edges.all(10),
    radiusSizeType: SizeType.PIXEL,
  );

  /// Create bubble.
  BubbleContainer({
    @required Drawable drawable,
    Drawable parent,
  })  : _drawable = drawable,
        super(parent: parent) {
    drawable.sizeChanges.listen((change) => _updateSize(change.newSize));
    _updateSize(drawable.size);

    drawable.setParent(this);
  }

  /// Update bubble size.
  void _updateSize(Size size) {
    setSize(
      width: size.width + _scaledPadding * 2,
      height: size.height + _scaledPadding * 2 + _scaledArrowHeight,
    );
  }

  @override
  void draw() {
    _roundRect.render(
        ctx,
        Rectangle<double>(
          0,
          _verticalArrowOrientation == VerticalArrowOrientation.BOTTOM ? 0 : _scaledArrowHeight,
          size.width,
          size.height - _scaledArrowHeight,
        ));

    _drawArrow(
      _horizontalArrowOrientation == HorizontalArrowOrientation.START ? _scaledPadding * 2 : _scaledPadding * 2 + _horizontalFreeDiff,
      _verticalArrowOrientation == VerticalArrowOrientation.BOTTOM ? size.height - _scaledArrowHeight : _scaledArrowHeight,
      _scaledArrowHeight,
    );

    _drawable.render(
      ctx,
      lastPassTimestamp,
      x: _scaledPadding,
      y: _scaledPadding + (_verticalArrowOrientation == VerticalArrowOrientation.TOP ? _scaledArrowHeight : 0),
    );
  }

  @override
  Point<int> calculateRenderingPosition(double x, double y) {
    if (isInvalid) {
      _determineArrowOrientation(x: x, y: y); // Recalculate the arrow position
    }

    return Point<int>(
      (_horizontalArrowOrientation == HorizontalArrowOrientation.START ? x - _scaledPadding * 2 : x - _scaledPadding * 2 - _horizontalFreeDiff).round(),
      (_verticalArrowOrientation == VerticalArrowOrientation.BOTTOM ? y - size.height : y).round(),
    );
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update
  }

  /// Determine the arrow orientations based on the [x] and [y] coordinates to point to with the arrow.
  /// It will determine the orientation using the size of the root canvas.
  void _determineArrowOrientation({
    double x, // Where the arrow should point to x
    double y, // Where the arrow should point to y
  }) {
    if (hasCurrentDrawableContext) {
      Size rootSize = currentDrawableContext.rootSize;

      double ySpace = rootSize.height - size.height;
      double xSpace = rootSize.width - size.width;

      // Check vertical orientation
      // Check if bubble fits in
      if (ySpace < 0) {
        // Bubble does not fit in vertically -> Set to default orientation
        _verticalArrowOrientation = VerticalArrowOrientation.BOTTOM;
      } else {
        // Check if bubble fits above object to point to
        _verticalArrowOrientation = y >= size.height ? VerticalArrowOrientation.BOTTOM : VerticalArrowOrientation.TOP;
      }

      // Check horizontal orientation
      // Check if bubble fits in
      if (xSpace < 0) {
        // Bubble does not fit in horizontally -> Set to default orientation
        _horizontalArrowOrientation = HorizontalArrowOrientation.START;
      } else {
        // Check if bubble fits left of the object to point to
        _horizontalArrowOrientation = x - _scaledPadding * 2 > xSpace ? HorizontalArrowOrientation.FREE : HorizontalArrowOrientation.START;

        if (_horizontalArrowOrientation == HorizontalArrowOrientation.FREE) {
          // Calculate the correct arrow position
          double diff = (x - _scaledPadding * 2) - xSpace;

          _horizontalFreeDiff = min(diff, size.width - _scaledPadding * 4);
        }
      }
    } else {
      // Cannot determine the orientation because the root canvas size is not supplied.
      _verticalArrowOrientation = VerticalArrowOrientation.BOTTOM;
      _horizontalArrowOrientation = HorizontalArrowOrientation.START;
    }
  }

  void _drawArrow(double x, double y, double size) {
    if (_verticalArrowOrientation == VerticalArrowOrientation.TOP) {
      size = -size;
    }

    setFillColor(color);

    ctx.beginPath();

    ctx.moveTo(x, y + size);
    ctx.lineTo(x - size / 2, y);
    ctx.lineTo(x + size / 2, y);

    ctx.fill();
  }

  Color get color => _color;

  set color(Color value) {
    _color = value;

    _roundRect.color = value;

    invalidate();
  }

  double get padding => _padding;

  set padding(double value) {
    _padding = value;
    _scaledPadding = window.devicePixelRatio * _padding;

    _updateSize(_drawable.size);
    invalidate();
  }

  double get arrowHeight => _arrowHeight;

  set arrowHeight(double value) {
    _arrowHeight = value;
    _scaledArrowHeight = window.devicePixelRatio * _arrowHeight;

    _updateSize(_drawable.size);
    invalidate();
  }
}

enum VerticalArrowOrientation {
  TOP,
  BOTTOM,
}

enum HorizontalArrowOrientation {
  START,
  FREE,
}
