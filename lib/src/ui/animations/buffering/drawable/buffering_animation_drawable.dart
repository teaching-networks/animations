/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/horizontal_alignment.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/vertical_layout.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plot.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/plottable_function.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/axis_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/coordinate_system_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/plot_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/button/button_drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/slider/slider_drawable.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/graph2d.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/renderables/graph2d_series.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/style/graph2d_style.dart';
import 'package:hm_animations/src/ui/canvas/text/baseline.dart';
import 'package:hm_animations/src/ui/canvas/text/text_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:vector_math/vector_math.dart' as vector;

typedef _DataPacket _TransformFunction(_DataPacket packet);

/// The root drawable of the buffering animation.
class BufferingAnimationDrawable extends Drawable {
  /// Size of the media to be transmitted in bytes.
  static final int _TRANSMISSION_SIZE = 1024 * 20;

  /// Maximum transmission unit in bytes.
  static final int _MTU = 1500;

  /// Bitrate of the media to be transmitted (in bit per second).
  static final int _BITRATE = 1000 * 1000 * 5;

  /// Quaternion used to rotate an arrow head vector to the left.
  static vector.Quaternion _rotateLeft = vector.Quaternion.axisAngle(vector.Vector3(0.0, 0.0, 1.0), pi / 4 * 3);

  /// Quaternion used to rotate an arrow head vector to the right.
  static vector.Quaternion _rotateRight = vector.Quaternion.axisAngle(vector.Vector3(0.0, 0.0, 1.0), -pi / 4 * 3);

  /// Random number generator used to generate seeds for another random number generator.
  static Random _rng = Random();

  /// Slider used to specify the playback buffer size.
  _SliderContainer _playoutBufferSizeSlider;

  /// Slider used to specify the mean network rate.
  _SliderContainer _meanNetworkRateSlider;

  /// Slider used to specify the variance of the network rate.
  _SliderContainer _networkRateVarianceSlider;

  /// Graph to display the result in.
  Graph2D _graph;

  /// Plot to display the result with.
  Plot _plot;

  /// Button used to trigger reseeding the random number generator.
  ButtonDrawable _reseedButton;

  /// Current seed for the random number generator.
  int _currentSeed;

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
        meanNetworkRate: _meanNetworkRateSlider.slider.value.toInt() * 1024,
        networkRateVariance: _networkRateVarianceSlider.slider.value.toInt() * 1024,
      );
    };

    _playoutBufferSizeSlider = _createSlider(
      label: "Playout buffer size",
      changeCallback: changeCallback,
      min: 0,
      max: _TRANSMISSION_SIZE.toDouble(),
      value: 128,
      step: 8,
      valueFormatter: (value) => "${value.toInt()} Byte",
    );

    _meanNetworkRateSlider = _createSlider(
      label: "Mean network rate",
      changeCallback: (value) {
        _networkRateVarianceSlider.slider.max = value;
        changeCallback(value);
      },
      min: 8,
      max: 1024,
      value: 128,
      step: 8,
      valueFormatter: (value) => "${value.toInt()} kByte/s",
    );

    _networkRateVarianceSlider = _createSlider(
      label: "Network rate variance",
      changeCallback: changeCallback,
      min: 0,
      max: _meanNetworkRateSlider.slider.value,
      value: 32,
      step: 8,
      valueFormatter: (value) => "${value.toInt()} kByte/s",
    );

    _graph = Graph2D(minX: 1, maxX: 3);
    _plot = Plot(
      parent: this,
      yMax: 100,
      xMax: 5,
      style: PlotStyle(
        coordinateSystem: CoordinateSystemStyle(
          xAxis: AxisStyle(
            label: "Time",
            color: Colors.SLATE_GREY,
            lineWidth: 2,
          ),
          yAxis: AxisStyle(
            label: "Cumulative data",
            color: Colors.SLATE_GREY,
            lineWidth: 2,
          ),
        ),
      ),
    );

    _plot.add(PlottableFunction(fct: (x) => x));
    _plot.add(PlottableFunction(fct: (x) => pow(x, 2)));
    _plot.add(PlottableFunction(fct: (x) => sin(x)));

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
  }) {
    int size = _TRANSMISSION_SIZE;
    int mtu = _MTU;
    int bitRate = _BITRATE;

    _graph.removeAll();

    final constantBitRateTransmissionSeries = _generateConstantBitRateTransmissionSeries(
      size: size,
      mtu: mtu,
      bitRate: bitRate,
    );

    final random = Random(_currentSeed);
    final networkDelayedSeries = _transformTransmissionSeries(
      constantBitRateTransmissionSeries,
      (packet) {
        double networkRate = meanNetworkRate + (networkRateVariance > 0 ? ((random.nextDouble() - 0.5 * 2) * networkRateVariance) : 0);
        double duration = packet.size / networkRate;

        return _DataPacket(size: packet.size, receivedTime: packet.receivedTime + duration);
      },
    );
    networkDelayedSeries.sort((p1, p2) => p1.receivedTime.compareTo(p2.receivedTime));

    double playoutTime;
    int remainingPlayOutBufferSize = playOutBufferSize;
    for (_DataPacket p in networkDelayedSeries) {
      remainingPlayOutBufferSize -= p.size;

      if (remainingPlayOutBufferSize <= 0) {
        playoutTime = p.receivedTime;
        break;
      }
    }
    if (remainingPlayOutBufferSize > 0) {
      playoutTime = networkDelayedSeries.last.receivedTime;
    }

    double playoutTimeDiff = playoutTime - constantBitRateTransmissionSeries.first.receivedTime;
    final playoutSeries = _transformTransmissionSeries(
      constantBitRateTransmissionSeries,
      (packet) {
        return _DataPacket(size: packet.size, receivedTime: packet.receivedTime + playoutTimeDiff);
      },
    );

    // Adjust graph axis dimensions
    _graph.minY = 0;
    _graph.minX = 0;
    _graph.maxY = size;
    _graph.maxX = max(playoutSeries.last.receivedTime, networkDelayedSeries.last.receivedTime);

    // Add series to graph
    _graph.add(_toGraph2DSeries(
      constantBitRateTransmissionSeries,
      style: Graph2DStyle(color: Colors.PINK_RED_2, fillArea: false),
      maxX: _graph.maxX,
    ));
    _graph.add(_toGraph2DSeries(
      networkDelayedSeries,
      style: Graph2DStyle(color: Colors.BLUE_GRAY, fillArea: false),
      maxX: _graph.maxX,
    ));
    _graph.add(_toGraph2DSeries(
      playoutSeries,
      style: Graph2DStyle(color: Colors.GREY_GREEN, fillArea: true),
      maxX: _graph.maxX,
    ));

    invalidate();
  }

  /// Generate series for a constant bit rate media transmission.
  List<_DataPacket> _generateConstantBitRateTransmissionSeries({
    int size = 1024 * 1024 * 100, // Size of the media to transmit (bytes)
    int mtu = 1500, // Maximum transmission unit (bytes)
    int bitRate = 5 * 1000 * 1000, // Constant bit rate to play the media with (bit per second)
  }) {
    int packetCount = (size / mtu).ceil();
    double secondsPerMTU = mtu / (bitRate / 8);

    List<_DataPacket> series = new List<_DataPacket>(packetCount);

    int remainingBytes = size;
    for (int i = 0; i < packetCount; i++) {
      int size = i == packetCount - 1 ? remainingBytes : mtu;

      series[i] = _DataPacket(
        size: size,
        receivedTime: (i + 1) * secondsPerMTU,
      );

      remainingBytes -= mtu;
    }

    return series;
  }

  /// Transform the passed series of data packets with the given transformation function.
  List<_DataPacket> _transformTransmissionSeries(List<_DataPacket> series, _TransformFunction transformFct) {
    List<_DataPacket> result = new List<_DataPacket>(series.length);

    for (int i = 0; i < result.length; i++) {
      result[i] = transformFct(series[i]);
    }

    return result;
  }

  /// Convert the passed list of data packets to a Graph2D series.
  Graph2DSeries _toGraph2DSeries(
    List<_DataPacket> packets, {
    Graph2DStyle style = const Graph2DStyle(),
    double maxX,
  }) {
    List<Point<double>> result = new List<Point<double>>(packets.length * 2 + 1);

    int cumSize = 0;
    for (int i = 0; i < packets.length; i++) {
      _DataPacket p = packets[i];

      int index = i * 2;

      result[index] = Point<double>(p.receivedTime, cumSize.toDouble());

      cumSize += p.size;
      result[index + 1] = Point<double>(p.receivedTime, cumSize.toDouble());
    }

    final lastReal = result[result.length - 2];

    // Add imaginary last point to fill the graph until the end of the graphs coordinate system.
    result.last = Point<double>(maxX, lastReal.y);

    return Graph2DSeries(series: result, style: style);
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
        _reseedButton.size.width;
    double controlsHeight = max(
      max(
        max(
          _playoutBufferSizeSlider.drawable.size.height,
          _meanNetworkRateSlider.drawable.size.height,
        ),
        _networkRateVarianceSlider.drawable.size.height,
      ),
      _reseedButton.size.height,
    );

    _drawControls(
      controlsWidth,
      controlsHeight,
      controlsPadding,
    );

    double graphSpacing = 10 * window.devicePixelRatio;

    _drawGraph(
      x: 0,
      y: controlsHeight + graphSpacing,
      width: size.width,
      height: size.height - controlsHeight - graphSpacing,
    );

    _drawLegend(
      x: 0,
      y: 0,
      width: (size.width - controlsWidth) / 2,
      height: controlsHeight,
      items: [
        _LegendItem(color: Colors.PINK_RED_2, text: "Constant bitrate transmission"),
        _LegendItem(color: Colors.BLUE_GRAY, text: "Network delayed receiving at client"),
        _LegendItem(color: Colors.GREY_GREEN, text: "Constant bitrate playout at client"),
      ],
    );
  }

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

  /// Draw an arrow and return its bounds.
  void _drawArrowHead({
    vector.Vector2 direction,
    double size = 10,
    double x = 0,
    double y = 0,
  }) {
    double hypo = sqrt(2 * pow(size / 2, 2));

    vector.Vector3 dir3D = vector.Vector3(direction.x, direction.y, 0);

    vector.Vector3 leftHead = _rotateLeft.rotated(dir3D);
    leftHead.length = hypo;

    vector.Vector3 rightHead = _rotateRight.rotated(dir3D);
    rightHead.length = hypo;

    double x1 = x + leftHead.x;
    double x2 = x + rightHead.x;
    double y1 = y + leftHead.y;
    double y2 = y + rightHead.y;

    ctx.beginPath();
    ctx.moveTo(x1, y1);
    ctx.lineTo(x, y);
    ctx.lineTo(x2, y2);
    ctx.fill();
  }

  /// Draw the sliders to control the animation.
  void _drawControls(double width, double height, double padding) {
    double offsetX = (size.width - width) / 2;

    _playoutBufferSizeSlider.drawable.render(
      ctx,
      lastPassTimestamp,
      x: offsetX,
    );

    _meanNetworkRateSlider.drawable.render(
      ctx,
      lastPassTimestamp,
      x: offsetX + _playoutBufferSizeSlider.drawable.size.width + padding,
    );

    _networkRateVarianceSlider.drawable.render(
      ctx,
      lastPassTimestamp,
      x: offsetX + _playoutBufferSizeSlider.drawable.size.width + padding + _meanNetworkRateSlider.drawable.size.width + padding,
    );

    _reseedButton.render(
      ctx,
      lastPassTimestamp,
      x: offsetX +
          _playoutBufferSizeSlider.drawable.size.width +
          padding +
          _meanNetworkRateSlider.drawable.size.width +
          padding +
          _networkRateVarianceSlider.drawable.size.width +
          padding,
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
    // Nothing to update.
  }
}

class _SliderContainer {
  final SliderDrawable slider;
  final Drawable drawable;

  _SliderContainer(this.slider, this.drawable);
}

class _DataPacket {
  /// Size of the packet.
  final int size;

  /// Time the data is received.
  final double receivedTime;

  _DataPacket({
    this.size,
    this.receivedTime,
  });
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
