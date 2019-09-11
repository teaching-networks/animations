/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/animations/media_access_control/cdma/graph/signal_graph.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/input/checkbox/checkbox_drawable.dart';
import 'package:hm_animations/src/ui/canvas/input/text/input_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/misc/image/image_info.dart';
import 'package:hm_animations/src/ui/misc/image/images.dart';
import 'package:tuple/tuple.dart';
import 'package:vector_math/vector_math.dart' as vector;

/// Main drawable for the CDMA animation.
class CDMADrawable extends Drawable {
  /// Allowed runes as input (0 and 1).
  static const List<int> _allowedRunes = [48, 49];

  /// Amount of connections.
  static const int _connectionCount = 4;

  /// The code length to use.
  static const int _codeLength = 4;

  /// Length of the input pattern to transfer.
  static const int _inputLength = 4;

  /// The default codes.
  static const List<List<double>> _defaultCodes = [
    [1, 1, 1, 1],
    [1, -1, 1, -1],
    [1, 1, -1, -1],
    [1, -1, -1, 1],
  ];

  /// Random number generator of the drawable.
  Random _rng = Random();

  /// Code for each sender and receiver.
  List<List<double>> _codes = CDMADrawable._defaultCodes;

  List<List<double>> _input = List<List<double>>(CDMADrawable._connectionCount);

  /// Input drawables for each sender to input the signal to send.
  List<InputDrawable> _inputDrawables = List<InputDrawable>(CDMADrawable._connectionCount);

  /// Signal graph for each sender.
  List<SignalGraph> _inputSignals = List<SignalGraph>(CDMADrawable._connectionCount);

  /// Signal graph for each code.
  List<SignalGraph> _codeGraphs = List<SignalGraph>(CDMADrawable._connectionCount);

  /// Signal graph for each code division.
  List<SignalGraph> _encodedInputSignals = List<SignalGraph>(CDMADrawable._connectionCount);

  /// Signal graph for each receiver.
  List<SignalGraph> _receiverSignalGraphs = List<SignalGraph>(CDMADrawable._connectionCount);

  /// Signal graph for each received signal.
  List<SignalGraph> _receiverEncodedSignalGraphs = List<SignalGraph>(CDMADrawable._connectionCount);

  /// Signal graph visualizing the channel.
  SignalGraph _channelSignalGraph;

  /// Image info for the cdma code image.
  ImageInfo _cdmaCodeInfo;

  /// The loaded cdma code image.
  CanvasImageSource _cdmaCodeImage;

  /// Image info for the cdma input image.
  ImageInfo _cdmaInputInfo;

  /// The loaded cdma input image.
  CanvasImageSource _cdmaInputImage;

  /// Drawable drawing a checkbox.
  CheckboxDrawable _checkboxDrawable;

  /// Subscription to the checkbox checked events.
  StreamSubscription<bool> _checkboxSub;

  /// Whether to simulate random transmission errors.
  bool _randomErrors = false;

  /// Current list of error factors to apply when [_randomErrors] is set to true.
  List<double> _errorFactors = List<double>(CDMADrawable._inputLength * CDMADrawable._codeLength);

  /// Create drawable.
  CDMADrawable() {
    _init();
  }

  @override
  void cleanup() {
    _checkboxSub.cancel();

    super.cleanup();
  }

  /// Initialize the drawable.
  void _init() {
    _checkboxDrawable = CheckboxDrawable(
      parent: this,
      label: "Zufallsfehler",
      checked: _randomErrors,
    );
    _checkboxSub = _checkboxDrawable.checkedChanges.listen((checked) {
      _randomErrors = checked;

      if (_randomErrors) {
        for (int i = 0; i < _errorFactors.length; i++) {
          _errorFactors[i] = _rng.nextDouble() - 0.5;
        }
      }

      _updateChannelGraph();
      _updateReceiverGraphs();
    });

    _channelSignalGraph = SignalGraph(parent: this, sectionSeparatorDistance: CDMADrawable._codeLength);

    for (int i = 0; i < CDMADrawable._connectionCount; i++) {
      _codeGraphs[i] = SignalGraph(parent: this, signal: _codes[i], signalColor: Colors.ORANGE);
      _inputSignals[i] = SignalGraph(parent: this, sectionSeparatorDistance: CDMADrawable._codeLength);
      _encodedInputSignals[i] = SignalGraph(parent: this, sectionSeparatorDistance: CDMADrawable._codeLength);
      _receiverSignalGraphs[i] = SignalGraph(parent: this, sectionSeparatorDistance: CDMADrawable._codeLength);
      _receiverEncodedSignalGraphs[i] = SignalGraph(parent: this, sectionSeparatorDistance: CDMADrawable._codeLength);

      _input[i] = List<double>(CDMADrawable._inputLength);
    }

    for (int i = 0; i < CDMADrawable._connectionCount; i++) {
      _inputDrawables[i] = _createInputDrawable((newValue) => _onInputUpdate(i, newValue));
    }

    _initImages();
  }

  /// Initialize the images needed by the drawable.
  Future<void> _initImages() async {
    _cdmaCodeInfo = Images.cdmaCode;
    _cdmaCodeImage = await _cdmaCodeInfo.load();

    _cdmaInputInfo = Images.cdmaInput;
    _cdmaInputImage = await _cdmaInputInfo.load();

    invalidate();
  }

  /// Create an input drawable.
  InputDrawable _createInputDrawable(OnChange onChange) => InputDrawable(
        parent: this,
        fontFamily: 'Roboto',
        maxLength: CDMADrawable._inputLength,
        width: 100,
        value: _generateRandomInputSequence(),
        filter: (toInsert) => toInsert.runes.firstWhere((c) => !CDMADrawable._allowedRunes.contains(c), orElse: () => -1) == -1,
        onChange: onChange,
      );

  /// Generate a random input sequence.
  String _generateRandomInputSequence() {
    StringBuffer sb = StringBuffer();

    for (int i = 0; i < CDMADrawable._inputLength; i++) {
      sb.write(_rng.nextInt(2));
    }

    return sb.toString();
  }

  @override
  void draw() {
    int rows = 4;
    int columns = 3;

    double cellW = size.width / columns;
    double cellH = size.height / rows;

    final connectingOperatorInfo = _drawChannel(x: cellW, y: 0, width: cellW, height: cellH * rows);

    double boxPadding = cellH * 0.05;
    double boxSpacing = cellH * 0.2;

    for (int i = 0; i < rows; i++) {
      _drawSenderBox(
        i,
        x: 0,
        y: cellH * i,
        width: cellW,
        height: cellH,
        connectTo: connectingOperatorInfo.item2,
        connectOffset: connectingOperatorInfo.item1,
        padding: boxPadding,
        spacing: boxSpacing,
      );
    }

    for (int i = 0; i < rows; i++) {
      _drawReceiverBox(
        i,
        x: cellW * 2,
        y: cellH * i,
        width: cellW,
        height: cellH,
        padding: boxPadding,
        spacing: boxSpacing,
      );
    }
  }

  /// Draw an operator bubble.
  void _drawOperator(
    String text, {
    double x = 0,
    double y = 0,
    double size = 50,
  }) {
    double radius = size / 2;
    double fontSize = size * 0.75;

    ctx.beginPath();
    ctx.ellipse(x, y, radius, radius, 2 * pi, 0, 2 * pi, false);

    setFillColor(Colors.PINK_RED_2);
    ctx.fill();

    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    setFillColor(Colors.WHITE);
    ctx.font = "bold ${fontSize}px monospace";

    ctx.fillText(text, x, y);
  }

  /// Draw an arrow between the two points [from] and [to].
  void _drawArrow(
    Point<double> from,
    Point<double> to, {
    double headSize = 8,
    double lineWidth = 2,
    double headAngle = pi * 0.15,
  }) {
    headSize *= window.devicePixelRatio;
    lineWidth *= window.devicePixelRatio;
    headAngle -= pi;

    setStrokeColor(Colors.SPACE_BLUE);
    ctx.lineWidth = lineWidth;

    ctx.beginPath();
    ctx.moveTo(from.x, from.y);
    ctx.lineTo(to.x, to.y);
    ctx.stroke();

    vector.Vector3 arrowV = vector.Vector3(to.x - from.x, to.y - from.y, 0);
    vector.Quaternion rotateLeft = vector.Quaternion.axisAngle(vector.Vector3(0.0, 0.0, 1.0), headAngle);
    vector.Vector3 leftHead = rotateLeft.rotated(arrowV);
    leftHead.length = headSize;
    vector.Quaternion rotateRight = vector.Quaternion.axisAngle(vector.Vector3(0.0, 0.0, 1.0), -headAngle);
    vector.Vector3 rightHead = rotateRight.rotated(arrowV);
    rightHead.length = headSize;

    ctx.beginPath();
    ctx.moveTo(to.x + leftHead.x, to.y + leftHead.y);
    ctx.lineTo(to.x, to.y);
    ctx.lineTo(to.x + rightHead.x, to.y + rightHead.y);
    ctx.stroke();
  }

  /// Draw a sender box.
  void _drawSenderBox(
    int index, {
    double x,
    double y,
    double width,
    double height,
    double connectOffset,
    Point<double> connectTo,
    double padding,
    double spacing,
  }) {
    InputDrawable input = _inputDrawables[index];

    double heightLeft = height - padding - input.size.height;

    double graphHeight = (heightLeft - padding * 2 - spacing) / 2;
    double codeGraphWidth = (width - padding * 2 - spacing) / (CDMADrawable._inputLength + 1);
    double graphWidth = codeGraphWidth * CDMADrawable._inputLength;
    double graphXOffset = x + codeGraphWidth + padding + spacing;
    double graphYOffset = y + padding + input.size.height;

    double inputBoxXOffset = graphXOffset + (graphWidth - input.size.width) / 2;
    input.render(ctx, lastPassTimestamp, x: inputBoxXOffset, y: y + padding);

    if (_cdmaInputImage != null) {
      double imgHeight = input.size.height;
      double imgWidth = imgHeight * _cdmaInputInfo.aspectRatio;

      ctx.drawImageToRect(
        _cdmaInputImage,
        Rectangle<double>(
          inputBoxXOffset - imgWidth - 5,
          y + padding,
          imgWidth,
          imgHeight,
        ),
      );
    }

    SignalGraph codeGraph = _codeGraphs[index];
    codeGraph.setSize(width: codeGraphWidth, height: graphHeight);
    double codeGraphYOffset = graphYOffset + (heightLeft - graphHeight) / 2;
    codeGraph.render(ctx, lastPassTimestamp, x: x + padding, y: codeGraphYOffset);

    if (_cdmaCodeImage != null) {
      double imgHeight = graphHeight / 2;
      double imgWidth = imgHeight * _cdmaCodeInfo.aspectRatio;

      ctx.drawImageToRect(
        _cdmaCodeImage,
        Rectangle<double>(
          x + padding + codeGraphWidth - imgWidth,
          codeGraphYOffset - imgHeight - padding,
          imgWidth,
          imgHeight,
        ),
      );
    }

    SignalGraph inputSg = _inputSignals[index];
    inputSg.setSize(width: codeGraphWidth, height: graphHeight);
    inputSg.render(ctx, lastPassTimestamp, x: graphXOffset + (graphWidth - codeGraphWidth) / 2, y: graphYOffset + padding);

    SignalGraph encodedSg = _encodedInputSignals[index];
    encodedSg.setSize(width: graphWidth, height: graphHeight);
    encodedSg.render(ctx, lastPassTimestamp, x: graphXOffset, y: graphYOffset + padding + spacing + graphHeight);

    double operatorSize = spacing - 2 * padding;
    _drawOperator("∗", x: graphXOffset + graphWidth / 2, y: graphYOffset + padding + graphHeight + spacing / 2, size: operatorSize);
    _drawArrow(
      Point<double>(graphXOffset + graphWidth / 2, graphYOffset),
      Point<double>(graphXOffset + graphWidth / 2, graphYOffset + padding),
    );
    _drawArrow(
      Point<double>(graphXOffset + graphWidth / 2, graphYOffset + padding + graphHeight),
      Point<double>(graphXOffset + graphWidth / 2, graphYOffset + padding * 2 + graphHeight),
    );
    _drawArrow(
      Point<double>(graphXOffset + graphWidth / 2, graphYOffset + padding + graphHeight + spacing - padding),
      Point<double>(graphXOffset + graphWidth / 2, graphYOffset + padding + graphHeight + spacing),
    );
    _drawArrow(
      Point<double>(x + padding + codeGraphWidth, graphYOffset + padding + graphHeight + spacing / 2),
      Point<double>(graphXOffset + graphWidth / 2 - operatorSize / 2, graphYOffset + padding + graphHeight + spacing / 2),
    );

    // Draw arrow which connects to a point outside of the sender box
    Point<double> from = Point<double>(width - padding, graphYOffset + padding + graphHeight * 1.5 + spacing);
    vector.Vector2 connectToV = vector.Vector2(connectTo.x - from.x, connectTo.y - from.y)..length -= connectOffset;
    _drawArrow(
      from,
      Point<double>(from.x + connectToV.x, from.y + connectToV.y),
    );
  }

  /// Draw a receiver box.
  void _drawReceiverBox(
    int index, {
    double x,
    double y,
    double width,
    double height,
    double padding,
    double spacing,
  }) {
    SignalGraph codeGraph = _codeGraphs[index];

    double operatorSize = spacing - 2 * padding;

    double codeGraphYOffset = y + height - padding - codeGraph.size.height;
    codeGraph.render(ctx, lastPassTimestamp, x: x + padding, y: codeGraphYOffset);

    double graphXOffset = x + padding + codeGraph.size.width + spacing;
    double encodedGraphHeight = height - padding * 2 - spacing - codeGraph.size.height;

    SignalGraph encodedSg = _receiverEncodedSignalGraphs[index];
    encodedSg.setSize(width: width - padding * 2 - spacing - codeGraph.size.width, height: encodedGraphHeight);
    encodedSg.render(ctx, lastPassTimestamp, x: graphXOffset, y: y + padding);

    SignalGraph resultSg = _receiverSignalGraphs[index];
    resultSg.setSize(width: codeGraph.size.width, height: codeGraph.size.height);
    resultSg.render(ctx, lastPassTimestamp,
        x: graphXOffset + (encodedSg.size.width - codeGraph.size.width) / 2, y: y + height - padding - resultSg.size.height);

    double operatorXOffset = x + padding + codeGraph.size.width / 2;
    double operatorYOffset = y + height / 2;
    _drawOperator("∗", x: operatorXOffset, y: operatorYOffset, size: operatorSize);
    _drawArrow(
      Point<double>(x, size.height / 2),
      Point<double>(operatorXOffset - operatorSize / 2, operatorYOffset),
    );
    _drawArrow(
      Point<double>(operatorXOffset, codeGraphYOffset),
      Point<double>(operatorXOffset, operatorYOffset + operatorSize / 2),
    );
    _drawArrow(
      Point<double>(operatorXOffset + operatorSize / 2, operatorYOffset),
      Point<double>(x + padding + codeGraph.size.width + spacing, y + padding + encodedGraphHeight / 2),
    );
    _drawOperator("/", x: graphXOffset + encodedSg.size.width / 2, y: y + encodedGraphHeight + padding + spacing / 2, size: operatorSize);
    _drawArrow(
      Point<double>(graphXOffset + encodedSg.size.width / 2, y + encodedGraphHeight + padding),
      Point<double>(graphXOffset + encodedSg.size.width / 2, y + encodedGraphHeight + padding + spacing / 2 - operatorSize / 2),
    );
    _drawArrow(
      Point<double>(graphXOffset + encodedSg.size.width / 2, y + height - codeGraph.size.height - padding - spacing / 2 + operatorSize / 2),
      Point<double>(graphXOffset + encodedSg.size.width / 2, y + height - codeGraph.size.height - padding),
    );
  }

  /// Draw the channel visualization.
  /// It returns the radius and position of the operation bubbles.
  Tuple2<double, Point<double>> _drawChannel({
    double x,
    int y,
    double width,
    double height,
  }) {
    double operationBubbleSize = height * 0.04;
    _drawOperator("+", x: x + operationBubbleSize / 2, y: y + height / 2, size: operationBubbleSize);

    SignalGraph sg = _channelSignalGraph;

    sg.setSize(width: width - operationBubbleSize * 1.5, height: height / 3);
    sg.render(ctx, lastPassTimestamp, x: x + operationBubbleSize * 1.5, y: y + height / 3);

    _drawArrow(Point<double>(x + operationBubbleSize, y + height / 2), Point<double>(x + operationBubbleSize * 1.5, y + height / 2));

    _checkboxDrawable.render(
      ctx,
      lastPassTimestamp,
      x: x + operationBubbleSize * 1.5 + (sg.size.width - _checkboxDrawable.size.width) / 2,
      y: y + height / 3 + sg.size.height + 20 * window.devicePixelRatio,
    );

    return Tuple2(operationBubbleSize / 2, Point<double>(x + operationBubbleSize / 2, y + height / 2));
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update.
  }

  /// What should happen if a input value update is received.
  _onInputUpdate(int i, String newValue) {
    List<double> signal = List<double>(CDMADrawable._inputLength)..fillRange(0, CDMADrawable._inputLength, 0);

    int a = 0;
    for (final rune in newValue.runes) {
      int v = int.tryParse(String.fromCharCode(rune));
      if (v == null) {
        throw new Exception("Could not parse input value $newValue");
      }
      signal[a++] = v == 0 ? -1 : 1;
    }

    _input[i] = signal;
    _inputSignals[i].signal = signal;
    _encodedInputSignals[i].signal = _stretchSignal(signal, _codes[i]);

    _updateChannelGraph();
    _updateReceiverGraphs();
  }

  /// Update all receiver graphs.
  void _updateReceiverGraphs() {
    List<double> channelSignal = _channelSignalGraph.signal;

    for (int i = 0; i < CDMADrawable._connectionCount; i++) {
      List<double> code = _codes[i];
      SignalGraph encodedGraph = _receiverEncodedSignalGraphs[i];
      SignalGraph resultGraph = _receiverSignalGraphs[i];
      List<double> newEncodedSignal = List<double>();
      List<double> resultSignal = List<double>();

      for (int a = 0; a < CDMADrawable._inputLength; a++) {
        double resultValue = 0;
        for (int u = 0; u < code.length; u++) {
          int index = a * code.length + u;
          double codeBit = code[u];

          double encodedValue = 0;
          if (channelSignal.length > index) {
            encodedValue = channelSignal[index] * codeBit;
            resultValue += encodedValue;
          }
          newEncodedSignal.add(encodedValue);
        }
        resultSignal.add(resultValue / code.length);
      }

      encodedGraph.signal = newEncodedSignal;
      resultGraph.signal = resultSignal;
    }
  }

  /// Update the channel graph.
  void _updateChannelGraph() {
    List<double> signal = List<double>(CDMADrawable._codeLength * CDMADrawable._inputLength);
    for (int i = 0; i < signal.length; i++) {
      double value = 0;
      for (final graph in _encodedInputSignals) {
        if (graph.signal.length > i) {
          if (_randomErrors) {
            value += graph.signal[i] + graph.signal[i] * _errorFactors[i];
          } else {
            value += graph.signal[i];
          }
        }
      }
      signal[i] = value;
    }

    _channelSignalGraph.signal = signal;
  }

  /// Divide the passed signal with the passed code.
  List<double> _stretchSignal(List<double> signal, List<double> code) {
    List<double> result = List<double>(signal.length * code.length);

    for (int i = 0; i < signal.length; i++) {
      final bit = signal[i];
      for (int a = 0; a < code.length; a++) {
        final codeBit = code[a];
        result[i * code.length + a] = bit * codeBit;
      }
    }

    return result;
  }
}
