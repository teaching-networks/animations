import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/function/graph2d_function.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/util/size.dart';

/// Draw an arbitrary graph using this drawable.
class Graph2D extends CanvasDrawable {
  /// Functions to draw in the graph.
  List<Graph2DFunction> _functions = List<Graph2DFunction>();

  /// Minimum x-axis value.
  num _minX;

  /// Maximum x-axis value.
  num _maxX;

  /// Minimum y-axis value.
  num _minY;

  /// Maximum y-axis value.
  num _maxY;

  /// How many points to draw for the function.
  num _points;

  /// Alternative to [points].
  /// Sets the amount of pixel between two x coordinates to sample the functions.
  /// If this is set the value of [points] will no more be used.
  num _precision;

  /// Whether the [_valueCache] is valid at the moment.
  /// May change once the graphs values (e.g. [minX], [maxX], ...) change.
  bool _cacheValid = false;

  /// Distance from one sample to another from the last calculation.
  double _lastSampleDistance;

  /// Defines how much more samples are calculated out of the minX to maxX range.
  /// Example: 0.5 would precalculate the sample count * 0.5 more samples out of the x range.
  /// 0.0 would not precalculate anything.
  double _precalculationFactor;

  /// Cached values for the functions.
  List<List<Point<double>>> _valueCache;

  /// Minimum x value which has been cached.
  /// Since the x values are precalculated this might be smaller than [_minX].
  double _minXInCache;

  /// Maximum x value which has been cached.
  /// Since the x values are precalculated this might be higher than [_maxX].
  double _maxXInCache;

  /// Create new Graph2D.
  Graph2D({num minX = -1.0, num maxX = 1.0, num minY = -1.0, num maxY = 1.0, num points = 100, num precision = null, double precalculationFactor = 0.5})
      : this._minX = minX,
        this._maxX = maxX,
        this._minY = minY,
        this._maxY = maxY,
        this._points = points,
        this._precision = precision,
        this._precalculationFactor = precalculationFactor;

  /// Calculate values for all functions.
  List<List<Point<double>>> _calculateFunctions(List<Graph2DFunction> functions, int samples, double minValue, double maxValue) {
    List<List<Point<double>>> result = List<List<Point<double>>>(functions.length);

    for (int i = 0; i < functions.length; i++) {
      result[i] = _calculateFunction(functions[i], samples, minValue, maxValue);
    }

    return result;
  }

  /// Calculate values for the passed function.
  List<Point<double>> _calculateFunction(Graph2DFunction function, int samples, double minValue, double maxValue) {
    List<Point<double>> result = List<Point<double>>();

    double xDistance = (maxValue - minValue) / samples;
    double x = minValue;

    for (int i = 0; i <= samples; i++) {
      result.add(Point(x, function.processor(x)));

      x += xDistance;
    }

    _lastSampleDistance = xDistance;

    return result;
  }

  /// Rebuild the function value cache.
  void _rebuildCache(double pixelWidth) {
    int samples = _getSamples(pixelWidth);

    double valueLength = (_maxX - _minX).abs();
    double precalculateLength = valueLength * _precalculationFactor;
    double delta = precalculateLength / 2;

    _minXInCache = _minX - delta;
    _maxXInCache = _maxX + delta;

    _valueCache = _calculateFunctions(_functions, samples, _minXInCache, _maxXInCache);

    _cacheValid = true; // Mark cache as valid.
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();

    context.translate(rect.left, rect.top);

    if (!_cacheValid) {
      _rebuildCache(rect.width);
    }

    for (int i = 0; i < _functions.length; i++) {
      _renderGraph(context, Size(rect.width, rect.height), _functions[i], _valueCache[i]);
    }

    context.restore();
  }

  /// Render the graph on the canvas [context] with the specified [size] and already calculates [values] for a [function].
  void _renderGraph(CanvasRenderingContext2D context, Size size, Graph2DFunction function, List<Point<double>> values) {
    if (values.isNotEmpty) {
      context.beginPath();

      double yLength = _maxY - _minY;
      double xLength = _maxX - _minX;

      int samples = values.length;

      Point<double> sample;
      bool notDrawnAnythingYet = true;

      // first and last sample x offset for later use.
      double firstDrawnSampleXOffset;
      double lastDrawnSampleXOffset;
      for (int i = 0; i < samples; i++) {
        sample = values[i];

        if (sample.x + _lastSampleDistance < _minX) {
          continue; // Out of range from left -> skip!
        } else if (sample.x - _lastSampleDistance > _maxX) {
          break; // Out of range from right -> break because the next samples won't be shown either.
        } else {
          // In range (visible sample) -> draw it!

          double xPixel = _valueToPixel(sample.x, _minX, xLength, size.width);
          double yPixel = _toY(_valueToPixel(sample.y, _minY, yLength, size.height), size.height);

          if (notDrawnAnythingYet) {
            notDrawnAnythingYet = false;

            context.moveTo(xPixel, yPixel); // Position first point to draw.
            firstDrawnSampleXOffset = xPixel;
          } else {
            context.lineTo(xPixel, yPixel); // Draw next point to draw.
          }

          lastDrawnSampleXOffset = xPixel;
        }
      }

      context.lineJoin = 'round';
      context.lineWidth = window.devicePixelRatio * 3;
      setStrokeColor(context, function.style.color);
      context.stroke();

      if (function.style.fillArea) {
        setFillColor(context, Color.opacity(function.style.color, 0.2));

        // Close graph path over the bottom of the visible area.
        context.lineTo(lastDrawnSampleXOffset, size.height);
        context.lineTo(firstDrawnSampleXOffset, size.height);
        context.closePath();

        context.fill();
      }
    }
  }

  /// Invalidate the graph. Will recalculate everything.
  /// Do this for example from outside if functions change.
  void invalidate() => _invalidateCache();

  /// Invalidate the value cache. Needs to be recalculated afterwards.
  void _invalidateCache() => _cacheValid = false;

  /// Get samples to get for the function graphs.
  int _getSamples(double pixelWidth) => _precision != null ? (pixelWidth / _precision).round() : _points;

  /// Convert the passed y pixel to the real y pixel (invert it).
  double _toY(double yPixel, double height) => height - yPixel;

  /// Get the pixel for the passed value.
  double _valueToPixel(double value, double minValue, double length, double pixelSize) => (value - minValue) / length * pixelSize;

  /// Should be called when the x range changes (minX and maxX).
  /// Will check whether the cache should be invalidated.
  void _onXRangeChange() {
    if (_cacheValid) {
      if (minX < _minXInCache
          || maxX > _maxXInCache) {
        _invalidateCache();
      }
    }
  }

  /// Add a [function] to draw.
  void addFunction(Graph2DFunction function) {
    _functions.add(function);
    _invalidateCache();
  }

  /// Remove a [function] to draw.
  void removeFunction(Graph2DFunction function) {
    _functions.remove(function);
    _invalidateCache();
  }

  /// Translate whole graph area (min. and max. x and y values) by the passed [x] and [y].
  void translate(double x, double y) {
    _minX += x;
    _maxX += x;

    _minY += y;
    _maxY += y;

    _onXRangeChange();
  }

  num get precision => _precision;

  set precision(num value) {
    _precision = value;
    _invalidateCache();
  }

  num get points => _points;

  set points(num value) {
    _points = value;
    _invalidateCache();
  }

  num get maxY => _maxY;

  set maxY(num value) {
    _maxY = value;
  }

  num get minY => _minY;

  set minY(num value) {
    _minY = value;
  }

  num get maxX => _maxX;

  set maxX(num value) {
    _maxX = value;

    _onXRangeChange();
  }

  num get minX => _minX;

  set minX(num value) {
    _minX = value;

    _onXRangeChange();
  }
}
