import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
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

  /// Create layout
  VerticalLayout({
    @required Drawable parent,
    @required this.children,
    this.layoutMode = LayoutMode.FIT,
  }) : super(parent) {
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
    setSize(
      width: parent.size.width,
      height: parent.size.height,
    );
  }

  @override
  void layout() {
    if (children == null || children.isEmpty) {
      return;
    }

    double yOffset = 0;
    for (Drawable child in children) {
      child.render(ctx, lastPassTimestamp, y: yOffset);
      yOffset += child.size.height;
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
