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
  static const List<List<int>> _defaultCodes = [
    [1, 1, 1, 1],
    [1, 0, 1, 0],
    [1, 1, 0, 0],
    [1, 0, 0, 1],
  ];

  /// Random number generator of the drawable.
  Random _rng = Random();

  /// Code for each sender and receiver.
  List<List<int>> _codes = CDMADrawable._defaultCodes;

  List<List<int>> _input = List<List<int>>(CDMADrawable._connectionCount);

  /// Input drawables for each sender to input the signal to send.
  List<InputDrawable> _inputDrawables = List<InputDrawable>(CDMADrawable._connectionCount);

  /// Signal graph for each sender.
  List<SignalGraph> _senderSignalGraphs = List<SignalGraph>(CDMADrawable._connectionCount);

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
    for (int i = 0; i < CDMADrawable._connectionCount; i++) {
      _inputDrawables[i] = _createInputDrawable((newValue) => _onInputUpdate(i, newValue));

      _senderSignalGraphs[i] = SignalGraph(parent: this);
      _receiverSignalGraphs[i] = SignalGraph(parent: this);

      _input[i] = List<int>(CDMADrawable._inputLength);
    }

    _channelSignalGraph = SignalGraph(parent: this, signal: [0, 0, 0, 5, -3, 2, 1, 0, 0, 1, -1, 0, 1, 1, 1, 0]);
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
    InputDrawable input = _inputDrawables[index];
    input.render(ctx, lastPassTimestamp, x: x, y: y);

    SignalGraph sg = _senderSignalGraphs[index];
    sg.setSize(width: width, height: height);
    sg.render(ctx, lastPassTimestamp, x: x, y: y);
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
    int i = 0;
    for (final rune in newValue.runes) {
      int v = int.tryParse(String.fromCharCode(rune));
      if (v == null) {
        throw new Exception("Could not parse input value $newValue");
      }
      signal[i++] = v.toDouble();
    }

    this._senderSignalGraphs[i].signal = signal;
  }
}
