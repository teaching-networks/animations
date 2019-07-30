/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/interfaces/graph2d_calculatable.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/interfaces/graph2d_renderable.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/style/graph2d_style.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/util/size.dart';

/// Draw an arbitrary graph using this drawable.
class Graph2D extends CanvasDrawable {
  /// Functions to draw in the graph.
  List<Graph2DRenderable> _renderables = List<Graph2DRenderable>();

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

  /// Defines how much more samples are calculated out of the minX to maxX range.
  /// Example: 0.5 would precalculate the sample count * 0.5 more samples out of the x range.
  /// 0.0 would not precalculate anything.
  double _preCalculationFactor;

  /// Minimum x value which has been cached.
  /// Since the x values are precalculated this might be smaller than [_minX].
  double _minXInCache;

  /// Maximum x value which has been cached.
  /// Since the x values are precalculated this might be higher than [_maxX].
  double _maxXInCache;

  /// Create new Graph2D.
  Graph2D({num minX = -1.0, num maxX = 1.0, num minY = -1.0, num maxY = 1.0, num points = 100, num precision = null, double preCalculationFactor = 0.5})
      : this._minX = minX,
        this._maxX = maxX,
        this._minY = minY,
        this._maxY = maxY,
        this._points = points,
        this._precision = precision,
        this._preCalculationFactor = preCalculationFactor;

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();

    context.translate(rect.left, rect.top);

    if (!_cacheValid) {
      _rebuildCache(rect.width);
    }

    for (int i = 0; i < _renderables.length; i++) {
      _renderGraph(context, Size(rect.width, rect.height), _renderables[i]);
    }

    context.restore();
  }

  /// Render the passed [renderable] with the specified [size] and on the passed [context].
  void _renderGraph(CanvasRenderingContext2D context, Size size, Graph2DRenderable renderable) {
    List<Point<double>> samples = renderable.getSamples();

    if (samples.isEmpty) {
      return;
    }

    try {
      int firstIndex = _findFirstIndexToDraw(samples);
      int lastIndex = _findLastIndexToDraw(samples, firstIndex);

      double xRange = _maxX - _minX;
      double yRange = _maxY - _minY;

      // first and last sample x offset for later use.
      double firstDrawnSampleXOffset;
      double lastDrawnSampleXOffset;

      context.beginPath();

      // Draw all visible samples.
      double xPixel;
      double yPixel;
      for (int i = firstIndex; i <= lastIndex; i++) {
        Point<double> sample = samples[i];

        xPixel = _valueToPixel(sample.x, _minX, xRange, size.width);
        yPixel = _toY(_valueToPixel(sample.y, _minY, yRange, size.height), size.height);

        if (i == firstIndex) {
          context.moveTo(xPixel, yPixel); // First point to draw.
          firstDrawnSampleXOffset = xPixel;
        } else {
          context.lineTo(xPixel, yPixel); // Draw next point to draw.
        }

        lastDrawnSampleXOffset = xPixel;
      }

      Graph2DStyle style = renderable.getStyle();

      if (style.drawLine) {
        context.lineJoin = style.lineJoin;
        context.lineCap = style.lineCap;
        context.lineWidth = window.devicePixelRatio * 2;
        setStrokeColor(context, style.color);
        context.stroke();
      }

      if (style.fillArea) {
        setFillColor(context, Color.opacity(style.color, 0.2));

        // Close graph path over the bottom of the visible area.
        context.lineTo(lastDrawnSampleXOffset, size.height);
        context.lineTo(firstDrawnSampleXOffset, size.height);
        context.closePath();

        context.fill();
      }
    } catch (e) {
      // Do nothing.
    }
  }

  /// Find the first index to draw in the list of [samples].
  /// Returns either the index of the sample to draw first (the sample before the first visible one)
  /// or throws exception if there is no sample to draw at all.
  int _findFirstIndexToDraw(List<Point<double>> samples) {
    for (int i = 0; i < samples.length; i++) {
      if (samples[i].x >= _minX) {
        return max(0, i - 1); // Is visible
      }
    }

    throw Exception("No first sample to draw found.");
  }

  /// Find the last index to draw in the list of [samples] with a [startIndex].
  /// Returns either the index to draw last (sample after the last visible one) or throws an exception
  /// if there is no sample to draw at all.
  int _findLastIndexToDraw(List<Point<double>> samples, int startIndex) {
    if (samples.isEmpty) {
      throw Exception("No last sample to draw found.");
    }

    for (int i = startIndex; i < samples.length; i++) {
      if (samples[i].x > _maxX) {
        return i; // Is invisible
      }
    }

    return samples.length - 1;
  }

  /// Rebuild the value cache for all calculatable Graph2D components.
  void _rebuildCache(double pixelWidth) {
    int samples = _getSamples(pixelWidth);

    double valueLength = (_maxX - _minX).abs();
    double preCalculateLength = valueLength * _preCalculationFactor;
    double delta = preCalculateLength / 2;

    _minXInCache = _minX - delta;
    _maxXInCache = _maxX + delta;

    _calculateRenderables(_renderables, samples, _minXInCache, _maxXInCache);

    _cacheValid = true; // Mark cache as valid.
  }

  /// Calculate values for all calculatable Graph2D renderables.
  void _calculateRenderables(List<Graph2DRenderable> renderables, int samples, double minValue, double maxValue) {
    for (Graph2DRenderable renderable in renderables) {
      if (renderable is Graph2DCalculatable) {
        _recalculate(renderable as Graph2DCalculatable, samples, minValue, maxValue);
      }
    }
  }

  /// Calculate values for the passed function.
  void _recalculate(Graph2DCalculatable calculatable, int samples, double minValue, double maxValue) {
    List<Point<double>> result = List<Point<double>>();

    double xDistance = (maxValue - minValue) / samples;
    double x = minValue;

    for (int i = 0; i <= samples; i++) {
      result.add(Point(x, calculatable.getProcessor()(x)));

      x += xDistance;
    }

    calculatable.cached = result; // Store the result in Graph2D component cache
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
      if (minX < _minXInCache || maxX > _maxXInCache) {
        _invalidateCache();
      }
    }
  }

  /// Add a [renderable] to draw.
  void add(Graph2DRenderable renderable) {
    _renderables.add(renderable);
    _invalidateCache();
  }

  /// Remove a [renderable] to draw.
  void remove(Graph2DRenderable renderable) {
    _renderables.remove(renderable);
    _invalidateCache();
  }

  /// Remove all [renderables].
  void removeAll() {
    _renderables.clear();
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
