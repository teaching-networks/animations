/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/horizontal_alignment.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/layout.dart';
import 'package:hm_animations/src/util/size.dart';
import 'package:meta/meta.dart';

import 'layout_mode.dart';

/// Layout arranging multiple drawables vertically.
class VerticalLayout extends Layout {
  /// Children to layout vertically.
  final List<Drawable> children;

  /// Layout mode of the layout.
  final LayoutMode layoutMode;

  /// Alignment of the child drawables along the vertical axis.
  final HorizontalAlignment alignment;

  /// Create layout
  VerticalLayout({
    @required this.children,
    Drawable parent,
    this.layoutMode = LayoutMode.FIT,
    this.alignment = HorizontalAlignment.LEFT,
  }) : super(parent: parent) {
    _init();
  }

  /// Initialize the layout.
  void _init() {
    _recalculateSize();
  }

  /// Recalculate the size of the layouts drawable.
  void _recalculateSize() {
    switch (layoutMode) {
      case LayoutMode.FIT:
        _recalculateSizeFitMode();
        break;
      case LayoutMode.GROW:
        _recalculateSizeGrowMode();
        break;
      default:
        throw Exception("Layout mode unknown");
    }
  }

  void _recalculateSizeFitMode() {
    double width = 0;
    double height = 0;

    for (Drawable child in children) {
      Size childSize = child.size;

      width = max(width, childSize.width);
      height += childSize.height;
    }

    setSize(
      width: width,
      height: height,
    );
  }

  void _recalculateSizeGrowMode() {
    if (parent != null) {
      setSize(
        width: parent.size.width,
        height: parent.size.height,
      );
    }
  }

  @override
  void setParent(Drawable parent) {
    super.setParent(parent);

    _recalculateSize();
  }

  @override
  void layout() {
    if (children == null || children.isEmpty) {
      return;
    }

    double yOffset = 0;
    for (Drawable child in children) {
      child.render(ctx, lastPassTimestamp, y: yOffset, x: _calculateAlignmentOffset(child));
      yOffset += child.size.height;
    }
  }

  double _calculateAlignmentOffset(Drawable child) {
    switch (alignment) {
      case HorizontalAlignment.LEFT:
        return 0;
      case HorizontalAlignment.RIGHT:
        return size.width - child.size.width;
      case HorizontalAlignment.CENTER:
        return (size.width - child.size.width) / 2;
      default:
        throw Exception("Horizontal alignment unknown");
    }
  }

  @override
  void onChildSizeChange(SizeChange change) {
    if (layoutMode == LayoutMode.FIT) {
      double widthChange = change.newSize.width - change.oldSize.width;
      double heightChange = change.newSize.height - change.oldSize.height;

      setSize(
        width: size.width + widthChange,
        height: size.height + heightChange,
      );
    }
  }

  @override
  void onParentSizeChange(SizeChange change) {
    if (layoutMode == LayoutMode.GROW) {
      double width = change.newSize.width;
      double height = change.newSize.height / children.length;

      for (Drawable child in children) {
        child.setSize(
          width: width,
          height: height,
        );
      }

      setSize(
        width: change.newSize.width,
        height: change.newSize.height,
      );
    }
  }
}
