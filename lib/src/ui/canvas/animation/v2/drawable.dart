/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';
import 'dart:html';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable_context.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/canvas_context_util.dart';
import 'package:hm_animations/src/util/size.dart';
import 'package:meta/meta.dart';

typedef void CanvasPainter(CanvasImageSource src, Point<double> offset);

/// Next generation canvas animation class.
abstract class Drawable extends CanvasContextUtil {
  /// Id of the 2D canvas rendering context.
  static const _canvas2dRenderingContextId = "2d";

  /// Default width of the drawable.
  static const double _defaultWidth = 100;

  /// Default height of the drawable.
  static const double _defaultHeight = 150;

  /// Parent of the drawable (if any -> can be null).
  Drawable _parent;

  /// Canvas where to cache rendered content until it needs to be refreshed.
  CanvasElement _cacheCanvas;

  /// Size of the cached canvas.
  Size _cacheCanvasSize;

  /// Context of the cached canvas.
  CanvasRenderingContext2D _cacheCanvasContext;

  /// Whether the drawable needs to repaint itself the next rendering cycle.
  bool _invalid = true;

  /// Timestamp of the last rendering loop pass.
  num _lastPassTimestamp;

  /// X Offset of the last rendering loop pass.
  double _lastPassXOffset = 0;

  /// Y Offset of the last rendering loop pass.
  double _lastPassYOffset = 0;

  /// Relative offset of the cached canvas on the parent canvas of the last rendering.
  Point<double> _lastRenderOffset = Point<double>(0, 0);

  /// X Offset of the last rendering loop pass (Absolute means from the root drawable).
  double _lastRenderAbsoluteXOffset;

  /// Y Offset of the last rendering loop pass (Absolute means from the root drawable).
  double _lastRenderAbsoluteYOffset;

  /// Current context shared by multiple dependent drawables.
  DrawableContext _currentDrawableContext;

  /// Whether to propagate events to dependent drawables (Check if needs repaint, ...).
  bool _propagateEventsToDependentDrawables = true;

  /// List of dependent drawables.
  /// Dependent drawables will be checked for needed repaints and
  /// passed some additional info.
  Set<Drawable> _dependentDrawables;

  /// Stream controller managing size change events.
  StreamController<SizeChange> _sizeChangedController = StreamController<SizeChange>.broadcast(sync: true);

  /// Create drawable.
  Drawable({
    Drawable parent,
  }) {
    if (parent != null) {
      setParent(parent);
    }

    _init();
  }

  /// Initialize the drawable.
  void _init() {
    _cacheCanvas = CanvasElement();
    setSize();
    _cacheCanvasContext = _cacheCanvas.getContext(_canvas2dRenderingContextId);

    setUtilCanvasContext(_cacheCanvasContext);
  }

  /// Invalidate the drawable to repaint itself the next rendering cycle.
  void invalidate() {
    _invalid = true;
  }

  /// Validate the drawable.
  void validate() {
    _invalid = false;
  }

  /// Whether the drawable needs to be repainted.
  bool get isInvalid => _invalid || _dependentDrawablesNeedRepaint || needsRepaint();

  /// Get the drawables canvas rendering context.
  CanvasRenderingContext2D get ctx => _cacheCanvasContext;

  /// Get the last drawn drawable image.
  CanvasImageSource get image => _cacheCanvas;

  /// Render the drawable onto the passed canvas rendering [context].
  void render(
    CanvasRenderingContext2D context,
    num timestamp, {
    double x = 0,
    double y = 0,
    CanvasPainter painter,
  }) {
    _lastPassTimestamp = timestamp;
    _lastPassXOffset = x;
    _lastPassYOffset = y;

    _lastRenderOffset = calculateRenderingPosition(x, y);

    update(timestamp);

    if (isInvalid) {
      if (hasParent) {
        // Calculate the absolute position of the cached canvas from the root canvas.
        _lastRenderAbsoluteXOffset = _lastRenderOffset.x + _parent.lastRenderAbsoluteXOffset;
        _lastRenderAbsoluteYOffset = _lastRenderOffset.y + _parent.lastRenderAbsoluteYOffset;
      }

      // Repaint drawable
      _cacheCanvasContext.clearRect(0, 0, size.width, size.height);
      draw();

      validate(); // Drawable has been redrawn and thus is valid again!
    }

    if (painter == null) {
      if (context != null) {
        _drawOnCanvas(context, _cacheCanvas, _lastRenderOffset);
      }
    } else {
      painter(_cacheCanvas, _lastRenderOffset);
    }
  }

  /// Calculate the rendering position of the cached canvas.
  /// Override this method to position the canvas somewhere else.
  /// For example the x and y parameters of the render method could be interpreted as the center
  /// of the canvas to draw by returning something like Point<double>(x - size.width / 2, y - size.width / 2);
  Point<double> calculateRenderingPosition(double x, double y) => Point<double>(x, y);

  /// Draw cached canvas on the passed [context].
  void _drawOnCanvas(CanvasRenderingContext2D context, CanvasImageSource src, Point<double> offset) {
    context.drawImage(src, offset.x, offset.y);
  }

  /// Cleanup drawable if it will be destroyed.
  void cleanup() {
    _sizeChangedController.close();

    if (_hasDependentDrawables) {
      for (final drawable in _dependentDrawables) {
        drawable.cleanup();
      }
    }
  }

  /// Set the size of the drawable.
  void setSize({
    double width = _defaultWidth,
    double height = _defaultHeight,
  }) {
    if (_cacheCanvasSize == null || width != _cacheCanvasSize.width || height != _cacheCanvasSize.height) {
      Size oldSize = _cacheCanvasSize;

      _cacheCanvasSize = Size(width, height);

      _cacheCanvas.width = width.toInt();
      _cacheCanvas.height = height.toInt();

      _sizeChangedController.add(SizeChange(
        oldSize: oldSize,
        newSize: _cacheCanvasSize,
      ));

      invalidate();
    }
  }

  /// Add a drawable to be dependent to this drawable, in order to
  /// get some additional info in the dependent drawable and automatically check dependent
  /// drawable if it needs to be repainted.
  void _addDependentDrawable(Drawable drawable) {
    if (_dependentDrawables == null) {
      _dependentDrawables = Set<Drawable>();
    }

    if (!_dependentDrawables.contains(drawable) && drawable != this) {
      _dependentDrawables.add(drawable);

      _initDependentDrawable(drawable);
    }
  }

  /// Remove a dependent drawable from this drawable.
  // ignore: unused_element
  void _removeDependentDrawable(Drawable drawable) {
    if (_dependentDrawables != null) {
      _dependentDrawables.remove(drawable);
    }
  }

  /// Check if the drawable has dependent drawables specified.
  bool get _hasDependentDrawables => _dependentDrawables != null;

  /// Initialize dependent drawable.
  /// Basically set some info for the new dependent drawable (e. g. the root canvas size).
  void _initDependentDrawable(Drawable drawable) {
    // Pass over current context
    drawable.setDrawableContext(_currentDrawableContext);

    // Inherit options
    drawable.propagateEventsToDependentDrawables = _propagateEventsToDependentDrawables;
  }

  /// Whether the drawable has dependent drawables.
  bool get hasDependentDrawables => _dependentDrawables != null;

  /// Get all dependent drawables of this drawable. Do not mutate.
  Set<Drawable> get dependentDrawables => _dependentDrawables;

  /// Check if dependent drawables need to be repainted.
  bool get _dependentDrawablesNeedRepaint {
    if (!_propagateEventsToDependentDrawables || !_hasDependentDrawables) {
      return false;
    }

    for (final drawable in _dependentDrawables) {
      if (drawable.isInvalid) {
        return true;
      }
    }

    return false;
  }

  /// Set the current context shared by multiple dependent drawables.
  void setDrawableContext(DrawableContext context) {
    _currentDrawableContext = context;

    // Propagate
    if (_hasDependentDrawables) {
      for (final drawable in _dependentDrawables) {
        drawable.setDrawableContext(context);
      }
    }
  }

  /// Whether a drawable context has been specified.
  bool get hasCurrentDrawableContext => _currentDrawableContext != null;

  /// Get a stream emitting size changes.
  Stream<SizeChange> get sizeChanges => _sizeChangedController.stream;

  /// Get the current drawable context.
  DrawableContext get currentDrawableContext => _currentDrawableContext;

  /// Get the drawables size.
  Size get size => _cacheCanvasSize;

  /// Get the timestamp of the last rendering loop pass.
  num get lastPassTimestamp => _lastPassTimestamp;

  /// Get the x offset of the last rendering loop pass.
  double get lastPassXOffset => _lastPassXOffset;

  /// Get the y offset of the last rendering loop pass.
  double get lastPassYOffset => _lastPassYOffset;

  /// Get the (relative) render offset of the last rendering.
  Point<double> get lastRenderOffset => _lastRenderOffset;

  /// Get the x offset of the last rendering loop pass (Absolute -> From the root drawable).
  double get lastRenderAbsoluteXOffset => _lastRenderAbsoluteXOffset != null ? _lastRenderAbsoluteXOffset : _lastRenderOffset.x;

  /// Get the y offset of the last rendering loop pass (Absolute -> From the root drawable).
  double get lastRenderAbsoluteYOffset => _lastRenderAbsoluteYOffset != null ? _lastRenderAbsoluteYOffset : _lastRenderOffset.y;

  /// Set whether the drawable should propagate events to the dependent drawables (Check if needs repaint, ...).
  void set propagateEventsToDependentDrawables(bool check) => _propagateEventsToDependentDrawables = check;

  /// Check whether the drawable should propagate events to the dependent drawables (Check if needs repaint, ...).
  bool get propagateEventsToDependentDrawables => _propagateEventsToDependentDrawables;

  /// Check if the drawable has a parent drawable specified.
  bool get hasParent => _parent != null;

  /// Get the drawables parent (if any -> can be null).
  Drawable get parent => _parent;

  /// Set the parent of the drawable.
  void setParent(Drawable parent) {
    if (hasParent) {
      throw Exception("Drawable already has parent. Cannot switch to new parent.");
    }

    if (parent != null) {
      _parent = parent;
      parent._addDependentDrawable(this);
    }
  }

  /// Check if the passed absolute [pos] is contained within
  /// this drawable.
  bool containsPos(Point<double> pos) {
    double x = pos.x - lastRenderAbsoluteXOffset;
    double y = pos.y - lastRenderAbsoluteYOffset;

    return x >= 0 && x <= size.width && y >= 0 && y <= size.height;
  }

  /// Check if the drawable needs to be repainted.
  /// It will be repainted no matter what this method is stating in case you
  /// call [invalidate()].
  bool needsRepaint();

  /// Update the drawable state based on the passed [timestamp].
  /// NOTE: Also update child drawables in here!
  void update(num timestamp);

  /// Draw the things you need to draw!
  /// Use the provided canvas rendering context [ctx].
  /// You can check the drawable size by calling [getSize()].
  /// The current pass timestamp is available via [lastPassTimestamp].
  /// The current x & y offset is available via [lastPassXOffset] & [lastPassYOffset].
  void draw();
}

/// Change event of a drawables size.
class SizeChange {
  /// The old size of the drawable.
  final Size oldSize;

  /// The current (new) size of the drawable.
  final Size newSize;

  /// Create size change event.
  SizeChange({
    @required this.oldSize,
    @required this.newSize,
  });
}
