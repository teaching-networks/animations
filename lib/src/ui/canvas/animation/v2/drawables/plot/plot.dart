import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/cache/sample_cache.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/drawable/coordinate_system_drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/plottable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/plot_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/util/coordinate_system.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/util/range.dart';

/// A plot is able to show graphs via functions, series, ...
/// It is basically the API v2 implementation of the [Graph2D].
class Plot extends Drawable {
  /// List of plottables in the plot.
  final List<Plottable> _plottables = List<Plottable>();

  /// Caches for the plottable samples.
  final Map<Plottable, SampleCache> _sampleCaches = Map<Plottable, SampleCache>();

  /// Coordinate system of the plot.
  final CoordinateSystem2D _coordinateSystem;

  /// Style of the plot.
  final PlotStyle style;

  /// Quality of the plot in range [0.0; 1.0].
  /// 1.0 means that a point will be sampled for each pixel.
  double _quality;

  /// Drawable for the coordinate system.
  CoordinateSystemDrawable _coordinateSystemDrawable;

  /// Create plot.
  Plot({
    Drawable parent,
    double xMin = -1,
    double xMax = 1,
    double yMin = -1,
    double yMax = 1,
    this.style = const PlotStyle(),
    double quality = 0.2,
  })  : _quality = quality,
        _coordinateSystem = CoordinateSystem2D(
          xRange: Range<double>(min: xMin, max: xMax),
          yRange: Range<double>(min: yMin, max: yMax),
        ),
        super(parent: parent) {
    _init();
  }

  /// Initialize the drawable.
  void _init() {
    _coordinateSystemDrawable = CoordinateSystemDrawable(
      coordinateSystem: _coordinateSystem,
      style: style.coordinateSystem,
      parent: this,
    );
  }

  @override
  void setSize({
    double width = Drawable.defaultWidth,
    double height = Drawable.defaultHeight,
  }) {
    super.setSize(
      width: width,
      height: height,
    );

    if (_coordinateSystemDrawable != null) {
      _coordinateSystemDrawable.setSize(
        width: width,
        height: height,
      );
    }
  }

  /// Add all passed plottables to the plot.
  void addAll(Iterable<Plottable> plottables) {
    for (Plottable plottable in plottables) {
      add(plottable);
    }
  }

  /// Add a plottable to the plot.
  void add(Plottable plottable) {
    _plottables.add(plottable);
    _sampleCaches[plottable] = SampleCache(plottable: plottable);

    invalidate();
  }

  /// Remove a plottable from the plot.
  void remove(Plottable plottable) {
    if (_plottables.remove(plottable)) {
      _sampleCaches.remove(plottable);
    }

    invalidate();
  }

  /// Remove all plottables from the plot.
  void removeAll() {
    _plottables.clear();
    _sampleCaches.clear();

    invalidate();
  }

  /// Get the current plot quality.
  double get quality => _quality;

  /// Set the current plot quality.
  void set quality(double value) {
    _quality = value;

    invalidate();
  }

  /// Set the coordinate system.
  void setCoordinateSystem({
    double xMin = -1,
    double xMax = 1,
    double yMin = -1,
    double yMax = 1,
  }) {
    _coordinateSystem.xRange.min = xMin;
    _coordinateSystem.xRange.max = xMax;
    _coordinateSystem.yRange.min = yMin;
    _coordinateSystem.yRange.max = yMax;

    invalidate();
  }

  /// Set a new minimum x value of the coordinate system.
  void set minX(double newMinX) {
    _coordinateSystem.xRange.min = newMinX;

    invalidate();
  }

  /// Set a new maximum x value of the coordinate system.
  void set maxX(double newMaxX) {
    _coordinateSystem.xRange.max = newMaxX;

    invalidate();
  }

  /// Set a new minimum y value of the coordinate system.
  void set minY(double newMinY) {
    _coordinateSystem.yRange.min = newMinY;

    invalidate();
  }

  /// Set a new maximum y value of the coordinate system.
  void set maxY(double newMaxY) {
    _coordinateSystem.yRange.max = newMaxY;

    invalidate();
  }

  /// Set the x range of the coordinate system.
  void setXRange({
    double minX = -1,
    double maxX = 1,
  }) {
    _coordinateSystem.xRange.min = minX;
    _coordinateSystem.xRange.max = maxX;

    invalidate();
  }

  /// Set the y range of the coordinate system.
  void setYRange({
    double minY = -1,
    double maxY = 1,
  }) {
    _coordinateSystem.yRange.min = minY;
    _coordinateSystem.yRange.max = maxY;

    invalidate();
  }

  @override
  void draw() {
    _drawCoordinateSystem();
    _drawPlottables();
  }

  /// Draw the coordinate system.
  void _drawCoordinateSystem() {
    if (style.coordinateSystem == null) {
      return;
    }

    _coordinateSystemDrawable.render(ctx, lastPassTimestamp);
  }

  /// Draw all plottables.
  void _drawPlottables() {
    Rectangle<double> drawingArea = _coordinateSystemDrawable.getDrawingArea();

    int sampleCount = max((size.width * quality).toInt(), 2);

    for (SampleCache sampleCache in _sampleCaches.values) {
      List<Point<double>> samples = sampleCache.sample(
        xStart: _coordinateSystem.xRange.min,
        xEnd: _coordinateSystem.xRange.max,
        count: sampleCount,
      );

      if (samples.length < 2) {
        continue;
      }

      sampleCache.plottable.draw(ctx, samples.map((sample) => _toActualPixel(sample, drawingArea)).toList(growable: false));
    }
  }

  /// Convert the actual pixel of the passed relative point [p].
  Point<double> _toActualPixel(Point<double> p, Rectangle<double> drawingArea) {
    return Point<double>(
      drawingArea.left + p.x / _coordinateSystem.xRange.length * drawingArea.width,
      drawingArea.top + drawingArea.height - p.y / _coordinateSystem.yRange.length * drawingArea.height,
    );
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update
  }
}
