/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/extension/mouse_listener.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/util/size.dart';
import 'package:meta/meta.dart';

/// Text field which is drawable on a canvas.
class InputDrawable extends Drawable implements MouseListener {
  /// Controller emitting value changes.
  final StreamController<String> _valueChanges = StreamController<String>.broadcast(sync: false);

  /// Current value of the input.
  String _value;

  /// Max length of the text field.
  final int maxLength;

  /// Size of the font.
  int _fontSize;

  /// Family of the font.
  final String fontFamily;

  /// Color of the text.
  final Color textColor;

  /// Whether the input is currently focused.
  bool _isFocused = false;

  /// The current selection.
  _SelectionRange _selection;

  /// Event listener on the window.
  EventListener _windowMouseUpListener;

  /// Event listener for key down events on the window.
  EventListener _keyDownListener;

  /// Bounds of the text from the last rendering cycle.
  Rectangle<double> _textBounds;

  /// Width of each character of the last rendering cycle.
  List<double> _widthPerCharacter = [];

  /// Create new input drawable.
  InputDrawable({
    Drawable parent,
    String value = "",
    this.maxLength,
    int fontSize,
    this.fontFamily = "sans-serif",
    this.textColor = Colors.BLACK,
  })  : this._value = value,
        super(parent: parent) {
    _fontSize = fontSize != null ? fontSize : defaultFontSize;

    _init();
  }

  /// Initialize the drawable.
  void _init() {
    setSize(width: 500, height: 100);

    _windowMouseUpListener = (event) => _onWindowMouseUp(event);
    window.addEventListener("mouseup", _windowMouseUpListener);

    _keyDownListener = (event) => _onKeyDown(event);
    window.addEventListener("keydown", _keyDownListener);
  }

  /// What to do on mouse up on the window.
  void _onWindowMouseUp(MouseEvent event) {
    if (_isFocused) {
      _isFocused = false;
      invalidate();
    }
  }

  /// What to do on key down.
  void _onKeyDown(KeyboardEvent event) {
    if (_isFocused) {
      bool isBackSpaceKey = event.code == "Backspace";
      bool isPrintableKey = event.key.length == 1;
      bool isArrowLeftKey = event.code == "ArrowLeft";
      bool isArrowRightKey = event.code == "ArrowRight";
      bool isArrowKey = isArrowLeftKey || isArrowRightKey;
      bool isShift = event.shiftKey;
      bool isCtrl = event.ctrlKey;

      if (isBackSpaceKey) {
        if (!isCtrl) {
          delete(); // Delete one character (or selection)
        } else {
          clear(); // Delete everything
        }
      } else if (isArrowKey) {
        if (!isCtrl) {
          if (!isShift) {
            // Move by one character
            if (isArrowLeftKey) {
              selectRange(max(_selection.start - 1, 0), max(_selection.start - 1, 0));
            } else if (isArrowRightKey) {
              selectRange(min(_selection.end + 1, value.length), min(_selection.end + 1, value.length));
            }
          } else {
            // Select the next character
            if (isArrowLeftKey) {
              if (_selection.initialPos == _selection.end) {
                _selection = _SelectionRange(
                  initialPos: _selection.initialPos,
                  start: max(_selection.start - 1, 0),
                  end: _selection.end,
                );
              } else {
                _selection = _SelectionRange(
                  initialPos: _selection.initialPos,
                  start: _selection.start,
                  end: max(_selection.end - 1, 0),
                );
              }
            } else if (isArrowRightKey) {
              if (_selection.initialPos == _selection.start) {
                _selection = _SelectionRange(
                  initialPos: _selection.initialPos,
                  start: _selection.start,
                  end: min(_selection.end + 1, value.length),
                );
              } else {
                _selection = _SelectionRange(
                  initialPos: _selection.initialPos,
                  start: min(_selection.start + 1, value.length),
                  end: _selection.end,
                );
              }
            }
            invalidate();
          }
        } else {
          if (!isShift) {
            // Jump to the end or start of the input field
            if (isArrowLeftKey) {
              selectRange(0, 0);
            } else {
              selectRange(value.length, value.length);
            }
          } else {
            // Select everything from the current character to the end or start
            if (isArrowLeftKey) {
              _selection = _SelectionRange(
                initialPos: _selection.initialPos,
                start: 0,
                end: _selection.initialPos,
              );
            } else if (isArrowRightKey) {
              _selection = _SelectionRange(
                initialPos: _selection.initialPos,
                start: _selection.initialPos,
                end: value.length,
              );
            }
            invalidate();
          }
        }
      } else if (isCtrl) {
        if (event.code == "KeyA") {
          selectAll();
        } else if (event.code == "KeyC") {
          // Copy the selected value
        } else if (event.code == "KeyV") {
          // Paste the currently copied value
        }
      } else if (isPrintableKey) {
        insert(event.key);
      }
    }
  }

  /// Select all of the text in the input.
  void selectAll() {
    selectRange(0, value.length);
  }

  /// Select range of the text in the input from [start] to [end].
  void selectRange(int start, int end) {
    if (start < 0) {
      start = 0;
    }

    if (end > value.length) {
      end = value.length;
    }

    _selection = _SelectionRange(initialPos: start, start: start, end: end);

    invalidate();
  }

  /// Insert the passed [v].
  void insert(String v) {
    if (_selection.size == 0) {
      if (_selection.start > 0 && _selection.start < value.length) {
        value = value.substring(0, _selection.start) + v + value.substring(_selection.start);
      } else if (_selection.start == 0) {
        value = v + value;
      } else {
        value += v;
      }
    } else {
      value.replaceRange(_selection.start, _selection.end, v);
    }

    selectRange(_selection.start + 1, _selection.start + 1);

    invalidate();
  }

  /// Delete one character or the current selection (if any).
  void delete() {
    if (_selection.size == 0) {
      if (_selection.start > 0) {
        if (_selection.end < value.length) {
          value = value.substring(0, _selection.start) + value.substring(_selection.start + 1);
        } else {
          value = value.substring(0, _selection.start);
        }

        selectRange(_selection.start - 1, _selection.start - 1);
      }
    } else {
      value.replaceRange(_selection.start, _selection.end, "");
      selectRange(_selection.start, _selection.start);
    }

    invalidate();
  }

  /// Clear the input value.
  void clear() {
    value = "";
    _selection = _SelectionRange(initialPos: 0, start: 0, end: 0);

    invalidate();
  }

  /// What to do when the drawable is destroyed.
  void cleanup() {
    super.cleanup();

    window.removeEventListener("mouseup", _windowMouseUpListener);
    window.removeEventListener("keydown", _keyDownListener);
  }

  /// Get the current value of the input.
  String get value => _value;

  /// Set the current value of the input.
  set value(String value) {
    if (value == null) {
      value = "";
    }

    if (maxLength != null && value.length > maxLength) {
      throw Exception("the value to set is longer than the maximum allowed length of $maxLength");
    }

    _value = value;

    invalidate();
  }

  /// Listen to value changes of the input.
  Stream get valueChanges => _valueChanges.stream;

  @override
  void draw() {
    _drawBorder();
    _drawValue();
    _drawSelection();
  }

  /// Draw the input box border.
  void _drawBorder() {
    setStrokeColor(_isFocused ? Colors.SPACE_BLUE : Colors.BLACK);
    ctx.strokeRect(0, 0, size.width, size.height);
  }

  /// Draw the current value.
  void _drawValue() {
    ctx.textBaseline = "top";
    ctx.font = "${_fontSize}px $fontFamily";
    setFillColor(textColor);

    Size size = _calculateTextBounds(value);
    _textBounds = Rectangle<double>(0, 0, size.width, size.height); // TODO Add padding

    ctx.fillText(value, 0, 0); // TODO Add padding

    // Calculate size for each character in the value
    _widthPerCharacter.clear();
    for (final rune in value.runes) {
      String char = String.fromCharCode(rune);
      Size s = _calculateTextBounds(char);
      _widthPerCharacter.add(s.width);
    }
  }

  /// Draw the current selection.
  void _drawSelection() {
    if (_selection == null || !_isFocused) {
      return;
    }

    double startX = _getXOffsetForCharPos(_selection.start);
    double endX = _getXOffsetForCharPos(_selection.end);

    double x = _textBounds.left + startX;
    double y = _textBounds.top;
    double width = endX - startX;
    double height = _textBounds.height;

    var color = Colors.SPACE_BLUE;
    ctx.globalAlpha = 0.3;

    if (width == 0) {
      width = 2;
      color = Colors.BLACK;
      ctx.globalAlpha = 0.8;
    }

    setFillColor(color);
    ctx.fillRect(x, y, width, height);

    ctx.globalAlpha = 1.0;
  }

  /// Get the x offset for the passed character [pos].
  double _getXOffsetForCharPos(int pos) {
    double offset = 0;
    for (int i = 0; i < pos; i++) {
      offset += _widthPerCharacter[i];
    }

    return offset;
  }

  /// Calculate the passed text size for the current canvas context.
  Size _calculateTextBounds(String text) {
    TextMetrics metrics = ctx.measureText(text);

    return Size(metrics.width, _fontSize);
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update.
  }

  @override
  void onMouseDown(CanvasMouseEvent event) {
    if (!containsPos(event.pos)) {
      return;
    }

    if (!_isFocused) {
      _isFocused = true;

      // TODO Find cursor position in the text and set to selection accordingly
      print("absoluteX: $lastRenderAbsoluteXOffset, absoluteY: $lastRenderAbsoluteYOffset, mouse pos: ${event.pos}");
      selectRange(0, 0);

      invalidate();
    } else {
      // TODO Detect double click and select everything
      bool isDoubleClick = true;

      if (isDoubleClick) {
        selectAll();
      }
    }
  }

  @override
  void onMouseMove(CanvasMouseEvent event) {
    // TODO Change cursor style when hovering over the input!
  }

  @override
  void onMouseUp(CanvasMouseEvent event) {
    if (!containsPos(event.pos)) {
      return;
    }

    event.event.stopPropagation();
  }
}

/// A selection range for a text.
class _SelectionRange {
  /// Initial position of the selection.
  final int initialPos;

  /// Start of the selection.
  final int start;

  /// End of the selection.
  final int end;

  /// Create range
  _SelectionRange({
    @required this.initialPos,
    @required this.start,
    @required this.end,
  });

  /// Get the size of the selection.
  int get size => end - start;
}
