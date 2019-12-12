/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/horizontal_alignment.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/vertical_layout.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plot.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/animated/animated_plottable_series.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/plottable_series.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/style/line/line_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/style/plottable_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/style/point/point_painter.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/style/point/point_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/axis_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/coordinate_system_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/plot_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/tick_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/button/button_drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/slider/slider_drawable.dart';
import 'package:hm_animations/src/ui/canvas/text/baseline.dart';
import 'package:hm_animations/src/ui/canvas/text/text_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:tuple/tuple.dart';

/// The root drawable of the buffering animation.
class BufferingAnimationDrawable extends Drawable {
  /// Maximum transmission unit in bytes.
  static final int _MTU = 1500;

  /// Factor to slow the animation down.
  /// For example 1000: The animation is 1000 times slower.
  static final int _SLOWDOWN_FACTOR = 1000;

  /// Random number generator used to generate seeds for another random number generator.
  static Random _rng = Random();

  /// Slider used to specify the playback buffer size.
  _SliderContainer _playoutBufferSizeSlider;

  /// Slider used to specify the mean network rate.
  _SliderContainer _meanNetworkRateSlider;

  /// Slider used to specify the variance of the network rate.
  _SliderContainer _networkRateVarianceSlider;

  /// Slider used to specify the bit rate to stream with.
  _SliderContainer _bitRateSlider;

  /// Plot to display the result with.
  Plot _plot;

  /// Button used to trigger reseeding the random number generator.
  ButtonDrawable _reseedButton;

  /// Current seed for the random number generator.
  int _currentSeed;

  /// Animated plottable series showing the constant bit rate.
  AnimatedPlottableSeries _constantBitRatePlottable;

  /// Animated plottable series showing the network delayed series.
  AnimatedPlottableSeries _networkDelayedPlottable;

  /// Animated plottable series showing the playout at client series.
  AnimatedPlottableSeries _clientPlayOutPlottable;

  /// List of interruptions happened during client play out.
  List<Point<double>> _playOutInterruptions = List<Point<double>>();

  /// Operation running async to add the interrupt marker in the plot by the right time.
  Completer<void> _interruptOperation;

  /// Create the buffering animation drawable.
  BufferingAnimationDrawable() {
    _init();
  }

  /// Initialize the drawable.
  void _init() {
    _reseed(); // Initially seeding the random number generator.

    SliderValueChangeCallback changeCallback = (_) {
      _recalculateGraph(
        playOutBufferSize: _playoutBufferSizeSlider.slider.value.toInt(),
        meanNetworkRate: _meanNetworkRateSlider.slider.value.toInt() * 1000 * 1000 ~/ 8,
        networkRateVariance: _networkRateVarianceSlider.slider.value.toInt() * 1000 * 1000 ~/ 8,
        bitRate: _bitRateSlider.slider.value.toInt() * 1000,
      );
    };

    _playoutBufferSizeSlider = _createSlider(
      label: "Playout buffer size",
      changeCallback: changeCallback,
      min: 1,
      max: 10,
      value: 2,
      step: 1,
      valueFormatter: (value) => "${value.toInt()} MTUs",
    );

    _meanNetworkRateSlider = _createSlider(
      label: "Mean network rate",
      changeCallback: (value) {
        _networkRateVarianceSlider.slider.max = value;
        changeCallback(value);
      },
      min: 1,
      max: 100,
      value: 16,
      step: 1,
      valueFormatter: (value) => "${value.toInt()} Mbit/s",
    );

    _networkRateVarianceSlider = _createSlider(
      label: "Network rate variance",
      changeCallback: changeCallback,
      min: 0,
      max: _meanNetworkRateSlider.slider.value,
      value: 5,
      step: 1,
      valueFormatter: (value) => "${value.toInt()} Mbit/s",
    );

    _bitRateSlider = _createSlider(
      label: "Bit rate",
      changeCallback: changeCallback,
      min: 100,
      max: 20000,
      value: 5000,
      step: 100,
      valueFormatter: (value) => "${value.toInt()} kBit/s",
    );

    _plot = Plot(
      parent: this,
      yMin: 0,
      yMax: 10,
      xMin: 0,
      xMax: 0.05,
      style: PlotStyle(
        coordinateSystem: CoordinateSystemStyle(
          xAxis: AxisStyle(
            label: "Time in s",
            color: Colors.LIGHTGREY,
            lineWidth: 2,
            ticks: TickStyle(generator: TickStyle.fixedCountTicksGenerator(5)),
          ),
          yAxis: AxisStyle(
            label: "Cumulative data",
            color: Colors.LIGHTGREY,
            lineWidth: 2,
            ticks: TickStyle(generator: TickStyle.fixedCountTicksGenerator(2), labelRenderer: (value) => "$value × MTU"),
          ),
        ),
      ),
    );

    _reseedButton = ButtonDrawable(
      parent: this,
      text: "Reseed",
      onClick: () {
        _reseed();
        changeCallback(null);
      },
    );

    changeCallback(null);
  }

  /// Create a slider input control.
  _SliderContainer _createSlider({
    String label,
    SliderValueChangeCallback changeCallback,
    double min,
    double max,
    double value,
    double step,
    ValueFormatter valueFormatter,
  }) {
    var slider = SliderDrawable(
      value: value,
      min: min,
      max: max,
      step: step,
      changeCallback: changeCallback,
      style: SliderStyle(
        valueFormatter: valueFormatter,
      ),
    );

    var drawable = VerticalLayout(
      parent: this,
      alignment: HorizontalAlignment.CENTER,
      children: [
        TextDrawable(
          text: label,
        ),
        slider
      ],
    );

    return _SliderContainer(slider, drawable);
  }

  /// Recalculate the result graph.
  void _recalculateGraph({
    int playOutBufferSize,
    int meanNetworkRate,
    int networkRateVariance,
    int bitRate,
  }) {
    final double secondsPerMTU = _MTU / (bitRate / 8);

    if (_interruptOperation != null && !_interruptOperation.isCompleted) {
      _interruptOperation.complete();
    }

    _plot.removeAll(); // Reset plot

    // Create constant bit rate series
    _constantBitRatePlottable = AnimatedPlottableSeries(
      seriesGenerator: _constantBitRateSeriesGenerator(secondsPerMTU).iterator,
      style: PlottableStyle(line: LineStyle(color: Colors.PINK_RED_2)),
    );
    _plot.add(_constantBitRatePlottable);

    // Create network delayed series
    _networkDelayedPlottable = AnimatedPlottableSeries(
      seriesGenerator: _networkDelayedSeriesGenerator(secondsPerMTU, meanNetworkRate, networkRateVariance).iterator,
      style: PlottableStyle(line: LineStyle(color: Colors.BLUE_GRAY)),
    );
    _plot.add(_networkDelayedPlottable);

    // Create client playout series
    _clientPlayOutPlottable = AnimatedPlottableSeries(
      seriesGenerator: _clientPlayOutSeriesGenerator(secondsPerMTU, playOutBufferSize).iterator,
      style: PlottableStyle(line: LineStyle(color: Colors.GREY_GREEN)),
    );
    _plot.add(_clientPlayOutPlottable);

    _playOutInterruptions.clear();
    _plot.add(PlottableSeries(
      points: _playOutInterruptions,
      style: PlottableStyle(
        line: null,
        points: PointStyle(
          painter: PointPainterFactory.getInstance("o"),
          color: Colors.RED,
        ),
      ),
    ));

    invalidate();
  }

  /// Generator of the constant bit rate series.
  Iterable<Tuple2<Iterable<Point<double>>, Duration>> _constantBitRateSeriesGenerator(double secondsPerMTU) sync* {
    final double secondsPerMTUInSimulation = secondsPerMTU * _SLOWDOWN_FACTOR;
    final int millisecondsInSimulation = (secondsPerMTUInSimulation * 1000).toInt();

    yield Tuple2([Point<double>(0, 0), Point<double>(0, 0)], Duration(seconds: 0)); // Initial point

    double timeInSeconds = 0;
    double mtuCount = 0;
    while (true) {
      timeInSeconds += secondsPerMTU;

      _ensureVisibleInPlot(0, mtuCount + 1);
      yield Tuple2(
        [
          Point<double>(timeInSeconds, mtuCount),
          Point<double>(timeInSeconds, ++mtuCount),
        ],
        Duration(milliseconds: millisecondsInSimulation),
      );
    }
  }

  /// Generator of the network delayed series.
  Iterable<Tuple2<Iterable<Point<double>>, Duration>> _networkDelayedSeriesGenerator(double secondsPerMTU, int meanNetworkRate, int networkRateVariance) sync* {
    final random = Random(_currentSeed);

    yield Tuple2([Point<double>(0, 0), Point<double>(0, 0)], Duration(seconds: 0)); // Initial point

    double mtuCount = 0;
    bool isFirst = true;
    num lastReceived = secondsPerMTU;
    while (true) {
      // Check if packet already sent, otherwise it cannot be received and we need to append additional time
      bool readyToReceive = _constantBitRatePlottable.generatedCount - 1 > mtuCount + 1;

      double networkRate = meanNetworkRate.toDouble();
      if (networkRateVariance > 0) {
        networkRate += (random.nextDouble() - 0.5 * 2) * networkRateVariance;
      }

      double timeForPacket = _MTU / networkRate;
      if (!readyToReceive) {
        double timeToWait = _constantBitRatePlottable.next.first.x - lastReceived;
        timeForPacket += timeToWait;
      }

      int ms = (timeForPacket * _SLOWDOWN_FACTOR * 1000).toInt();
      if (isFirst) {
        isFirst = false;
        ms += (lastReceived * _SLOWDOWN_FACTOR * 1000).toInt();
      }

      lastReceived += timeForPacket;

      yield Tuple2(
        [
          Point<double>(lastReceived, mtuCount),
          Point<double>(lastReceived, ++mtuCount),
        ],
        Duration(milliseconds: ms),
      );
    }
  }

  /// Generator for the client playout series.
  Iterable<Tuple2<Iterable<Point<double>>, Duration>> _clientPlayOutSeriesGenerator(double secondsPerMTU, int bufferSize) sync* {
    final int neededBufferedPackets = bufferSize;

    yield Tuple2([Point<double>(0, 0), Point<double>(0, 0)], Duration(seconds: 0)); // Initial point

    bool playingOut = false; // Whether the streamed data is currently played out at client or buffering
    int playedOut = 0; // Number of packets played out.
    double lastReceived = 0;
    double lastPlayedOut = null;
    while (true) {
      double nextPacketReceivedTime = _networkDelayedPlottable.next.first.x;
      int receivedPackets = _networkDelayedPlottable.generatedCount - 2;
      int buffered = receivedPackets - playedOut;

      if (!playingOut && buffered >= neededBufferedPackets) {
        playingOut = true;
      }

      final bool waitForPacket = !playingOut || buffered <= 0 && nextPacketReceivedTime > lastPlayedOut + secondsPerMTU;
      if (waitForPacket) {
        _ensureVisibleInPlot(nextPacketReceivedTime, 0);

        if (playingOut) {
          // No more packets to play out. Play out is interrupted!
          double interruptionTime = lastPlayedOut + secondsPerMTU;

          _onPlayOutInterrupted(interruptionTime, lastPlayedOut, playedOut);
          yield Tuple2([Point<double>(nextPacketReceivedTime, playedOut.toDouble()), Point<double>(nextPacketReceivedTime, (++playedOut).toDouble())],
              Duration(milliseconds: ((nextPacketReceivedTime - lastPlayedOut) * _SLOWDOWN_FACTOR * 1000).toInt()));
          lastReceived = nextPacketReceivedTime;
          lastPlayedOut = nextPacketReceivedTime;
        } else {
          if (buffered + 1 >= neededBufferedPackets) {
            playingOut = true;
            yield Tuple2([Point<double>(nextPacketReceivedTime, playedOut.toDouble()), Point<double>(nextPacketReceivedTime, (++playedOut).toDouble())],
                Duration(milliseconds: ((nextPacketReceivedTime - lastReceived) * _SLOWDOWN_FACTOR * 1000).toInt()));
            lastReceived = nextPacketReceivedTime;
            lastPlayedOut = nextPacketReceivedTime;
          } else {
            yield Tuple2([Point<double>(nextPacketReceivedTime, playedOut.toDouble()), Point<double>(nextPacketReceivedTime, playedOut.toDouble())],
                Duration(milliseconds: ((nextPacketReceivedTime - lastReceived) * _SLOWDOWN_FACTOR * 1000).toInt()));
            lastReceived = nextPacketReceivedTime;
          }
        }
      } else {
        // Playing out buffered packet.
        _ensureVisibleInPlot(lastPlayedOut + secondsPerMTU, 0);
        yield Tuple2(
            [Point<double>(lastPlayedOut + secondsPerMTU, playedOut.toDouble()), Point<double>(lastPlayedOut + secondsPerMTU, (++playedOut).toDouble())],
            Duration(milliseconds: (secondsPerMTU * _SLOWDOWN_FACTOR * 1000).toInt()));
        lastPlayedOut += secondsPerMTU;
      }
    }
  }

  /// Ensure that the passed x and y coordinates are visible in the plot.
  void _ensureVisibleInPlot(double x, double y) {
    if (x > _plot.maxX) {
      _plot.maxX = x;
    }

    if (y > _plot.maxY) {
      _plot.maxY = y;
    }
  }

  /// Called when the play out at client is interrupted.
  void _onPlayOutInterrupted(double interruptionTime, double lastPlayedOutTime, int playedOut) {
    final completer = Completer<void>();
    _interruptOperation = completer;
    Future.delayed(Duration(milliseconds: ((interruptionTime - lastPlayedOutTime) * _SLOWDOWN_FACTOR * 1000).toInt())).then(
      (_) {
        if (!completer.isCompleted) {
          _playOutInterruptions.add(Point<double>(interruptionTime, playedOut.toDouble()));
          _plot.invalidate();
        }
      },
    );
  }

  /// Reseed the random number generator used by the animation.
  void _reseed() => _currentSeed = _rng.nextInt(9999999);

  @override
  void draw() {
    double controlsPadding = 10 * window.devicePixelRatio;
    double controlsWidth = _playoutBufferSizeSlider.drawable.size.width +
        controlsPadding +
        _meanNetworkRateSlider.drawable.size.width +
        controlsPadding +
        _networkRateVarianceSlider.drawable.size.width +
        controlsPadding +
        _reseedButton.size.width +
        controlsPadding +
        _bitRateSlider.drawable.size.width;
    double controlsHeight = maxValue([
      _playoutBufferSizeSlider.drawable.size.height,
      _meanNetworkRateSlider.drawable.size.height,
      _networkRateVarianceSlider.drawable.size.height,
      _bitRateSlider.drawable.size.height,
      _reseedButton.size.height,
    ]);

    _drawControls(
      x: 0,
      width: controlsWidth,
      height: controlsHeight,
      padding: controlsPadding,
    );

    _drawLegend(
      x: controlsWidth + controlsPadding,
      width: size.width - controlsWidth - controlsPadding,
      height: controlsHeight,
      items: [
        _LegendItem(color: Colors.PINK_RED_2, text: "Constant bitrate transmission"),
        _LegendItem(color: Colors.BLUE_GRAY, text: "Network delayed receiving at client"),
        _LegendItem(color: Colors.GREY_GREEN, text: "Constant bitrate playout at client"),
      ],
    );

    double graphSpacing = 10 * window.devicePixelRatio;

    _drawGraph(
      x: 0,
      y: controlsHeight + graphSpacing,
      width: size.width,
      height: size.height - controlsHeight - graphSpacing,
    );
  }

  /// Get the maximum value of the passed values.
  double maxValue(List<double> values) => values.reduce((currentMax, value) => max(currentMax, value));

  /// Draw the result graph.
  void _drawGraph({
    double x = 0,
    double y = 0,
    double width,
    double height,
  }) {
    _plot.setSize(
      width: width,
      height: height,
    );
    _plot.render(
      ctx,
      lastPassTimestamp,
      x: x,
      y: y,
    );
  }

  /// Draw the sliders to control the animation.
  void _drawControls({double x = 0, double y = 0, double width, double height, double padding}) {
    double offsetX = x;

    double currentOffset = offsetX;
    _playoutBufferSizeSlider.drawable.render(
      ctx,
      lastPassTimestamp,
      x: currentOffset,
    );

    currentOffset += _playoutBufferSizeSlider.drawable.size.width + padding;
    _meanNetworkRateSlider.drawable.render(
      ctx,
      lastPassTimestamp,
      x: currentOffset,
    );

    currentOffset += _meanNetworkRateSlider.drawable.size.width + padding;
    _networkRateVarianceSlider.drawable.render(
      ctx,
      lastPassTimestamp,
      x: currentOffset,
    );

    currentOffset += _networkRateVarianceSlider.drawable.size.width + padding;
    _bitRateSlider.drawable.render(
      ctx,
      lastPassTimestamp,
      x: currentOffset,
    );

    currentOffset += _bitRateSlider.drawable.size.width + padding;
    _reseedButton.render(
      ctx,
      lastPassTimestamp,
      x: currentOffset,
      y: (height - _reseedButton.size.height) / 2,
    );
  }

  /// Draw a legend explaining the graph.
  void _drawLegend({
    double x = 0,
    double y = 0,
    double width = 100,
    double height = 100,
    List<_LegendItem> items,
    double itemSpacing = 5,
  }) {
    assert(items.isNotEmpty);

    double totalSpacing = (items.length - 1) * itemSpacing;
    double heightPerItem = (height - totalSpacing) / items.length;
    double yOffset = y;

    for (_LegendItem item in items) {
      _drawLegendItem(
        x: x,
        y: yOffset,
        width: width,
        height: heightPerItem,
        item: item,
      );

      yOffset += heightPerItem + itemSpacing;
    }
  }

  /// Draw a legend item.
  void _drawLegendItem({
    double x,
    double y,
    double width,
    double height,
    _LegendItem item,
  }) {
    setFillColor(item.color);
    double cWidth = min(0.25 * width, 30 * window.devicePixelRatio);
    ctx.fillRect(x, y, cWidth, height);

    setFillColor(Colors.BLACK);
    setFont(baseline: TextBaseline.MIDDLE);
    ctx.fillText(item.text, x + cWidth + 5, y + height / 2, width - cWidth - 5);
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    if (_constantBitRatePlottable != null) if (_constantBitRatePlottable.requestUpdate(timestamp)) _plot.invalidate();
    if (_networkDelayedPlottable != null) if (_networkDelayedPlottable.requestUpdate(timestamp)) _plot.invalidate();
    if (_clientPlayOutPlottable != null) if (_clientPlayOutPlottable.requestUpdate(timestamp)) _plot.invalidate();
  }
}

class _SliderContainer {
  final SliderDrawable slider;
  final Drawable drawable;

  _SliderContainer(this.slider, this.drawable);
}

/// Item used in a legend.
class _LegendItem {
  /// Color to be explained.
  final Color color;

  /// Text explaining the colors meaning.
  final String text;

  /// Create item.
  _LegendItem({
    this.color,
    this.text,
  });
}
