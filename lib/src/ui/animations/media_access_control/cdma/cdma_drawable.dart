/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:math';

import 'package:hm_animations/src/ui/animations/media_access_control/cdma/graph/signal_graph.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/input/input_drawable.dart';

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
  List<SignalGraph> _senderSignalGraphs = List<SignalGraph>(CDMADrawable._connectionCount);

  /// Signal graph for each code.
  List<SignalGraph> _codeGraphs = List<SignalGraph>(CDMADrawable._connectionCount);

  /// Signal graph for each code division.
  List<SignalGraph> _stretchGraphs = List<SignalGraph>(CDMADrawable._connectionCount);

  /// Signal graph for each receiver.
  List<SignalGraph> _receiverSignalGraphs = List<SignalGraph>(CDMADrawable._connectionCount);

  /// Signal graph visualizing the channel.
  SignalGraph _channelSignalGraph;

  /// Create drawable.
  CDMADrawable() {
    _init();
  }

  /// Initialize the drawable.
  void _init() {
    _channelSignalGraph = SignalGraph(parent: this);

    for (int i = 0; i < CDMADrawable._connectionCount; i++) {
      _codeGraphs[i] = SignalGraph(parent: this, signal: _codes[i]);
      _senderSignalGraphs[i] = SignalGraph(parent: this, equalQuadrants: false);
      _stretchGraphs[i] = SignalGraph(parent: this, equalQuadrants: false);
      _receiverSignalGraphs[i] = SignalGraph(parent: this, equalQuadrants: false);

      _input[i] = List<double>(CDMADrawable._inputLength);
    }

    for (int i = 0; i < CDMADrawable._connectionCount; i++) {
      _inputDrawables[i] = _createInputDrawable((newValue) => _onInputUpdate(i, newValue));
    }
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

    for (int i = 0; i < rows; i++) {
      _drawSenderBox(i, x: 0, y: cellH * i, width: cellW, height: cellH);
    }

    _drawChannel(x: cellW, y: 0, width: cellW, height: cellH * rows);

    for (int i = 0; i < rows; i++) {
      _drawReceiverBox(i, x: cellW * 2, y: cellH * i, width: cellW, height: cellH);
    }
  }

  /// Draw a sender box.
  void _drawSenderBox(
    int index, {
    double x,
    double y,
    double width,
    double height,
  }) {
    double padding = height * 0.01;
    double curY = y + padding;

    InputDrawable input = _inputDrawables[index];
    input.render(ctx, lastPassTimestamp, x: x, y: curY);

    curY += input.size.height + padding;
    double heightLeft = height - padding * 2 - input.size.height;

    double graphWidth = width * 0.8;
    double graphHeight = (heightLeft - padding * 2) / 2;

    SignalGraph codeGraph = _codeGraphs[index];
    codeGraph.setSize(width: width * 0.2, height: graphHeight);
    codeGraph.render(ctx, lastPassTimestamp, x: x, y: curY + (heightLeft - graphHeight) / 2);

    SignalGraph sg = _senderSignalGraphs[index];
    sg.setSize(width: graphWidth, height: graphHeight);
    sg.render(ctx, lastPassTimestamp, x: x + codeGraph.size.width, y: curY);

    curY += graphHeight + padding;

    SignalGraph sg2 = _stretchGraphs[index];
    sg2.setSize(width: graphWidth, height: graphHeight);
    sg2.render(ctx, lastPassTimestamp, x: x + codeGraph.size.width, y: curY);
  }

  /// Draw a receiver box.
  void _drawReceiverBox(
    int index, {
    double x,
    double y,
    double width,
    double height,
  }) {
    SignalGraph sg = _receiverSignalGraphs[index];

    sg.setSize(width: width, height: height);
    sg.render(ctx, lastPassTimestamp, x: x, y: y);
  }

  /// Draw the channel visualization.
  void _drawChannel({
    double x,
    int y,
    double width,
    double height,
  }) {
    SignalGraph sg = _channelSignalGraph;

    sg.setSize(width: width, height: height / 3);
    sg.render(ctx, lastPassTimestamp, x: x, y: y + height / 3);
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update.
  }

  /// What should happen if a input value update is received.
  _onInputUpdate(int i, String newValue) {
    List<double> signal = List<double>(newValue.length);
    int a = 0;
    for (final rune in newValue.runes) {
      int v = int.tryParse(String.fromCharCode(rune));
      if (v == null) {
        throw new Exception("Could not parse input value $newValue");
      }
      signal[a++] = v == 0 ? -1 : 1;
    }

    _input[i] = signal;
    _senderSignalGraphs[i].signal = signal;
    _stretchGraphs[i].signal = _stretchSignal(signal, _codes[i]);

    _updateChannelGraph();
    _updateReceiverGraphs();
  }

  /// Update all receiver graphs.
  void _updateReceiverGraphs() {
    List<double> channelSignal = _channelSignalGraph.signal;

    for (int i = 0; i < CDMADrawable._connectionCount; i++) {
      List<double> code = _codes[i];
      SignalGraph graph = _receiverSignalGraphs[i];
      List<double> newSignal = List<double>();

      for (int a = 0; a < CDMADrawable._inputLength; a++) {
        double value = 0;
        for (int u = 0; u < code.length; u++) {
          int index = a * code.length + u;
          double codeBit = code[u];

          if (channelSignal.length > index) {
            value += codeBit * channelSignal[index];
          }
        }

        value /= code.length;
        newSignal.add(value);
      }

      graph.signal = newSignal;
    }
  }

  /// Update the channel graph.
  void _updateChannelGraph() {
    List<double> signal = List<double>(CDMADrawable._codeLength * CDMADrawable._inputLength);
    for (int i = 0; i < signal.length; i++) {
      double value = 0;
      for (final graph in _stretchGraphs) {
        if (graph.signal.length > i) {
          value += graph.signal[i];
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
