import 'dart:async';
import 'dart:html';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable_context.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/canvas_context_util.dart';
import 'package:hm_animations/src/util/size.dart';

/// Next generation canvas animation class.
abstract class Drawable extends CanvasContextUtil {
  /// Id of the 2D canvas rendering context.
  static const _canvas2dRenderingContextId = "2d";

  /// Default width of the drawable.
  static const double _defaultWidth = 100;

  /// Default height of the drawable.
  static const double _defaultHeight = 150;

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
  double _lastPassXOffset;

  /// Y Offset of the last rendering loop pass.
  double _lastPassYOffset;

  /// Current context shared by multiple dependent drawables.
  DrawableContext _currentDrawableContext;

  /// Whether to propagate events to dependent drawables (Check if needs repaint, ...).
  bool _propagateEventsToDependentDrawables = true;

  /// List of dependent drawables.
  /// Dependent drawables will be checked for needed repaints and
  /// passed some additional info.
  List<Drawable> _dependentDrawables;

  /// Stream controller managing size change events.
  StreamController<Size> _sizeChangedController = StreamController<Size>.broadcast(sync: true);

  /// Create drawable.
  /// Specify the drawables [parent] to automatically add it to its dependent drawables (Can be null).
  Drawable(
    Drawable parent,
  ) {
    _init(parent);
  }

  /// Initialize the drawable.
  void _init(Drawable parent) {
    _cacheCanvas = CanvasElement();
    setSize();
    _cacheCanvasContext = _cacheCanvas.getContext(_canvas2dRenderingContextId);

    setUtilCanvasContext(_cacheCanvasContext);

    if (parent != null) {
      parent.addDependentDrawable(this);
    }
  }

  /// Invalidate the drawable to repaint itself the next rendering cycle.
  void invalidate() {
    _invalid = true;
  }

  /// Validate the drawable.
  void _validate() {
    _invalid = false;
  }

  /// Whether the drawable needs to be repainted.
  bool get isInvalid => _invalid || _dependentDrawablesNeedRepaint || needsRepaint();

  /// Get the drawables canvas rendering context.
  CanvasRenderingContext2D get ctx => _cacheCanvasContext;

  /// Render the drawable onto the passed canvas rendering [context].
  void render(
    CanvasRenderingContext2D context,
    num timestamp, {
    double x = 0,
    double y = 0,
  }) {
    _lastPassTimestamp = timestamp;
    _lastPassXOffset = x;
    _lastPassYOffset = y;

    update(timestamp);

    if (isInvalid) {
      // Repaint drawable
      _cacheCanvasContext.clearRect(0, 0, size.width, size.height);
      draw();

      _validate(); // Drawable has been redrawn and thus is valid again!
    }

    drawOnCanvas(context, _cacheCanvas, x, y);
  }

  /// Draw cached canvas on the passed [context].
  /// Override this method if you need to adjust the cache canvas image alignment
  /// (for example centering the image where [x] and [y] is in the center).
  void drawOnCanvas(CanvasRenderingContext2D context, CanvasImageSource src, double x, double y) {
    context.drawImage(_cacheCanvas, x, y);
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
      _cacheCanvasSize = Size(width, height);

      _cacheCanvas.width = width.toInt();
      _cacheCanvas.height = height.toInt();

      _sizeChangedController.add(_cacheCanvasSize);

      invalidate();
    }
  }

  /// Add a drawable to be dependent to this drawable, in order to
  /// get some additional info in the dependent drawable and automatically check dependent
  /// drawable if it needs to be repainted.
  void addDependentDrawable(Drawable drawable) {
    if (_dependentDrawables == null) {
      _dependentDrawables = List<Drawable>();
    }

    _dependentDrawables.add(drawable);
    _initDependentDrawable(drawable);
  }

  /// Remove a dependent drawable from this drawable.
  void removeDependentDrawable(Drawable drawable) {
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
  Stream<Size> get sizeChanges => _sizeChangedController.stream;

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

  /// Set whether the drawable should propagate events to the dependent drawables (Check if needs repaint, ...).
  void set propagateEventsToDependentDrawables(bool check) => _propagateEventsToDependentDrawables = check;

  /// Check whether the drawable should propagate events to the dependent drawables (Check if needs repaint, ...).
  bool get propagateEventsToDependentDrawables => _propagateEventsToDependentDrawables;

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
