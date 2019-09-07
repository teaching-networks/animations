/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:async/async.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/extension/mouse_listener.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/edges.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/size_type.dart';
import 'package:hm_animations/src/ui/canvas/text/text_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/util/size.dart';
import 'package:meta/meta.dart';

typedef void OnChange(String value);

typedef bool Filter(String value);

/// Text field which is drawable on a canvas.
class InputDrawable extends Drawable implements MouseListener {
  /// Controller emitting value changes.
  final StreamController<String> _valueChanges = StreamController<String>.broadcast(sync: false);

  /// Current value of the input.
  String _value = "";

  /// Max length of the text field.
  final int maxLength;

  /// Size of the font.
  final double fontSize;

  /// Family of the font.
  final String fontFamily;

  /// Color of the text.
  final Color textColor;

  /// Callback emitting new values when they are typed in.
  final OnChange onChange;

  /// Filter filtering inserted strings.
  final Filter filter;

  /// Whether the input is currently focused.
  bool _isFocused = false;

  /// Whether the mouse is currently hovering over the drawables area.
  bool _isMouseIn = false;

  /// The current selection.
  _SelectionRange _selection;

  /// The current scroll position (x offset from the left).
  double _scrollPos = 0;

  /// Padding to the left and right.
  double _xScrollPadding = 3 * window.devicePixelRatio;

  /// Event listener on the window.
  EventListener _windowMouseUpListener;

  /// Event listener for key down events on the window.
  EventListener _keyDownListener;

  /// Event listener for paste events on the window.
  EventListener _pasteListener;

  /// Width of all substrings for each character of the current value.
  /// For example for the value "abc" there would be 3 entries in the
  /// list (when each character is 5 px width): [5, 10, 15].
  /// Of course the characters are not 5 px wide for each font, thus
  /// we need this lookup.
  List<double> _widthPerCharacter = [];

  /// Drawable to draw the text.
  TextDrawable _textDrawable;

  /// Operation to detect a double click.
  CancelableOperation _doubleClickDetector;

  /// Whether the input box is currently dragged on.
  bool _isMouseDown = false;

  /// Start selection position of the mouse.
  int _startSelectPos;

  /// Padding to use vertically.
  double _padding = 0;

  /// Round rectangle to draw the input box with.
  RoundRectangle _roundRect;

  /// Create new input drawable.
  InputDrawable({
    Drawable parent,
    String value = "",
    this.maxLength,
    this.fontSize,
    this.fontFamily = "sans-serif",
    this.textColor = Colors.BLACK,
    double width = 300,
    double padding = 6,
    this.onChange,
    this.filter,
  }) : super(parent: parent) {
    _padding = padding * window.devicePixelRatio;

    _init(width * window.devicePixelRatio);

    this.value = value;
  }

  /// Get the available window width.
  double get windowWidth => size.width - 2 * _xScrollPadding;

  /// Initialize the drawable.
  void _init(double width) {
    _windowMouseUpListener = (event) => _onWindowMouseUp(event);
    window.addEventListener("mouseup", _windowMouseUpListener);

    _keyDownListener = (event) => _onKeyDown(event);
    window.addEventListener("keydown", _keyDownListener);

    _pasteListener = (event) => _onPaste(event);
    window.addEventListener("paste", _pasteListener);

    _textDrawable = TextDrawable(
      parent: this,
      text: _value,
      alignment: TextAlignment.LEFT,
      color: textColor,
      lineHeight: 1.0,
      fontFamilies: fontFamily,
      textSize: fontSize,
    );

    _roundRect = RoundRectangle(
      radius: Edges.all(3 * window.devicePixelRatio),
      radiusSizeType: SizeType.PIXEL,
      strokeWidth: 2 * window.devicePixelRatio,
    );

    setSize(width: width, height: _textDrawable.size.height + _padding * 2);
  }

  /// What to do on a paste event on the window.
  void _onPaste(ClipboardEvent event) {
    if (!_isFocused) {
      return;
    }

    event.preventDefault();

    DataTransfer transferable = event.clipboardData;
    if (transferable == null) {
      return;
    }

    String toPaste = transferable.getData("text");
    insert(toPaste);
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
      bool isSpace = event.code == "Space";
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

            scrollToPos(_selection.start);
          } else {
            // Select the next character
            if (isArrowLeftKey) {
              if (_selection.initialPos == _selection.end) {
                _selection = _SelectionRange(
                  initialPos: _selection.initialPos,
                  start: max(_selection.start - 1, 0),
                  end: _selection.end,
                );

                scrollToPos(_selection.start);
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

                scrollToPos(_selection.end);
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

            scrollToPos(_selection.start);
          } else {
            // Select everything from the current character to the end or start
            if (isArrowLeftKey) {
              _selection = _SelectionRange(
                initialPos: _selection.initialPos,
                start: 0,
                end: _selection.initialPos,
              );

              scrollToPos(0);
            } else if (isArrowRightKey) {
              _selection = _SelectionRange(
                initialPos: _selection.initialPos,
                start: _selection.initialPos,
                end: value.length,
              );

              scrollToPos(value.length);
            }
            invalidate();
          }
        }
      } else if (isCtrl) {
        if (event.code == "KeyA") {
          selectAll();
          event.preventDefault();
        } else if (event.code == "KeyC") {
          copySelection();
        } else if (event.code == "KeyX") {
          // Cut the selected value
          copySelection();
          delete();
        }
      } else if (isPrintableKey || isSpace) {
        event.preventDefault();

        insert(event.key);
      }
    }
  }

  /// Get the currently selected text.
  String get selectedText => value.substring(_selection.start, _selection.end);

  /// Copy the current selected text.
  void copySelection() {
    TextAreaElement elm = document.createElement("textarea");
    elm.value = selectedText;

    elm.setAttribute("readonly", "");
    elm.style.position = "absolute";
    elm.style.left = "-10000px";

    document.body.children.add(elm);

    elm.select(); // Select text in the area
    document.execCommand("copy");

    document.body.children.remove(elm);
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
    if (start > value.length) {
      start = value.length;
    }
    if (end > value.length) {
      end = value.length;
    }

    _selection = _SelectionRange(initialPos: start, start: start, end: end);

    invalidate();
  }

  /// Scroll to the passed [pos].
  void scrollToPos(int pos) {
    if (_isOverflow) {
      if (pos < 0) {
        pos = 0;
      }
      if (pos > value.length) {
        pos = value.length;
      }

      double cursorOffset = _getXOffsetForCharPos(pos);

      if (cursorOffset < _scrollPos) {
        // Scroll left
        _scrollPos = max(cursorOffset - _xScrollPadding, 0);
      } else if (cursorOffset > _scrollPos + windowWidth) {
        // Scroll right
        _scrollPos = cursorOffset - windowWidth + _xScrollPadding;
      }
    } else {
      _scrollPos = 0;
    }
  }

  /// Validate the scroll position.
  void _validateScrollPos() {
    if (_isOverflow) {
      double maxScrollPos = _textDrawable.size.width - windowWidth;
      if (_scrollPos > maxScrollPos) {
        _scrollPos = maxScrollPos + _xScrollPadding;
      }
    } else {
      _scrollPos = 0;
    }
  }

  /// Insert the passed [v].
  void insert(String v) {
    if (v == null || v.length == 0) {
      return;
    }

    // The filter needs to approve the value to insert first
    if (filter != null && !filter(v)) {
      return;
    }

    bool replaceSelection = _selection.size != 0;
    if (!replaceSelection) {
      if (_selection.start > 0 && _selection.start < value.length) {
        value = value.substring(0, _selection.start) + v + value.substring(_selection.start);
      } else if (_selection.start == 0) {
        value = v + value;
      } else {
        value += v;
      }
    } else {
      value = value.replaceRange(_selection.start, _selection.end, v);
    }

    selectRange(_selection.start + v.length, _selection.start + v.length);

    scrollToPos(_selection.start);
    _validateScrollPos();

    invalidate();
  }

  /// Delete one character or the current selection (if any).
  void delete() {
    if (_selection.size == 0) {
      if (_selection.start > 0) {
        if (_selection.end < value.length) {
          value = value.substring(0, _selection.start - 1) + value.substring(_selection.start);
        } else {
          value = value.substring(0, _selection.start - 1);
        }

        selectRange(_selection.start - 1, _selection.start - 1);
      }
    } else {
      value = value.replaceRange(_selection.start, _selection.end, "");
      selectRange(_selection.start, _selection.start);
    }

    _validateScrollPos();

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
    window.removeEventListener("paste", _pasteListener);
  }

  /// Get the current value of the input.
  String get value => _value;

  /// Set the current value of the input.
  set value(String value) {
    if (value == null) {
      value = "";
    }

    if (maxLength != null && value.length > maxLength) {
      value = value.substring(0, maxLength);
    }

    _value = value;
    _textDrawable.text = value;

    // Calculate size for each character in the value
    _widthPerCharacter.clear();
    _textDrawable.setupCanvasContextFontSettings(ctx);
    String currentString = "";
    for (final rune in value.runes) {
      currentString += String.fromCharCode(rune);
      Size s = _textDrawable.calculateStringSize(currentString, context: ctx, setupContextFontSettings: false);
      _widthPerCharacter.add(s.width);
    }

    invalidate();

    if (onChange != null) {
      onChange(this.value);
    }
  }

  /// Listen to value changes of the input.
  Stream get valueChanges => _valueChanges.stream;

  @override
  void draw() {
    _drawBorder();
    _drawSelection();
    _drawValue();
  }

  /// Draw the input box border.
  void _drawBorder() {
    _roundRect.color = _isFocused ? Colors.SPACE_BLUE : Colors.LIGHTGREY;
    _roundRect.paintMode = PaintMode.STROKE;
    _roundRect.render(
      ctx,
      Rectangle<double>(
        _roundRect.strokeWidth,
        _roundRect.strokeWidth,
        size.width - 2 * _roundRect.strokeWidth,
        size.height - 2 * _roundRect.strokeWidth,
      ),
    );
  }

  /// Check if the text to display is currently overflowing the available space.
  bool get _isOverflow => _textDrawable.size.width > windowWidth;

  /// Draw the current value.
  void _drawValue() {
    if (value.length == 0) {
      return;
    }

    double width = _isOverflow ? windowWidth : _textDrawable.size.width;
    double height = _textDrawable.size.height;

    _textDrawable.render(ctx, lastPassTimestamp, painter: (image, offset) {
      ctx.drawImageToRect(image, Rectangle<double>(_xScrollPadding, _padding, width, height),
          sourceRect: Rectangle<double>(
            _scrollPos,
            0,
            width,
            height,
          ));
    });
  }

  /// Draw the current selection.
  void _drawSelection() {
    if (_selection == null || !_isFocused) {
      return;
    }

    double startX = _getXOffsetForCharPos(_selection.start) - _scrollPos;
    double endX = _getXOffsetForCharPos(_selection.end) - _scrollPos;

    double x = startX;
    double y = _padding;
    double width = endX - startX;
    double height = _textDrawable.size.height;

    var color = Colors.SPACE_BLUE;

    if (width == 0) {
      width = 2 * window.devicePixelRatio;
      color = Colors.DARK_GRAY;
    }

    setFillColor(color);
    ctx.fillRect(x, y, width, height);
  }

  /// Get the x offset for the passed character [pos].
  double _getXOffsetForCharPos(int pos) {
    if (pos == 0) {
      return _xScrollPadding;
    } else {
      return _widthPerCharacter[pos - 1] + _xScrollPadding;
    }
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update.
  }

  /// Get the correct character position for the passed x coordinate.
  int _getPosForXCoordinate(double x) {
    if (value.length == 0) {
      return 0;
    }

    int pos = 0;
    double xCoordLast = 0;
    for (double xCoord in _widthPerCharacter) {
      if (x < xCoord) {
        // Choose the nearest
        if ((x - xCoordLast) > (xCoord - x)) {
          pos++;
        }
        break;
      }

      xCoordLast = xCoord;
      pos++;
    }

    return pos;
  }

  @override
  void onMouseDown(CanvasMouseEvent event) {
    if (!containsPos(event.pos)) {
      _isFocused = false;
      invalidate();
      return;
    }

    event.event.preventDefault();

    if (!_isFocused) {
      _isFocused = true;
    }

    _isMouseDown = true;

    int pos = _getPosForXCoordinate(_scrollPos + event.pos.x - lastRenderAbsoluteXOffset);
    selectRange(pos, pos);

    _startSelectPos = pos;
  }

  /// On double click on the input.
  void _onDoubleClick() {
    selectAll();
  }

  @override
  void onMouseMove(CanvasMouseEvent event) {
    if (containsPos(event.pos)) {
      _isMouseIn = true;
      if (event.control.getCursorType() != "text") {
        event.control.setCursorType("text");
      }
    } else if (_isMouseIn) {
      _isMouseIn = false;
      _onMouseLeave(event);
    }

    if (_isMouseDown) {
      int pos = _getPosForXCoordinate(_scrollPos + event.pos.x - lastRenderAbsoluteXOffset);

      selectRange(min(_startSelectPos, pos), max(_startSelectPos, pos));
      scrollToPos(pos);
    }
  }

  /// What should happen when the mouse leaves the input drawable area.
  void _onMouseLeave(CanvasMouseEvent event) {
    if (event.control.getCursorType() == "text") {
      event.control.resetCursorType();
    }
  }

  @override
  void onMouseUp(CanvasMouseEvent event) {
    if (_isMouseDown) {
      _isMouseDown = false;
      event.event.stopPropagation();
    }

    if (!containsPos(event.pos)) {
      return;
    }

    event.event.stopPropagation();

    if (_doubleClickDetector != null) {
      _doubleClickDetector.cancel();
      _doubleClickDetector = null;
    } else {
      CancelableOperation op;
      op = CancelableOperation.fromFuture(
        Future.delayed(Duration(milliseconds: 300)).then((_) {
          if (op == _doubleClickDetector) {
            _doubleClickDetector = null;
          }
        }),
        onCancel: () {
          // Is double click!
          _onDoubleClick();
        },
      );
      _doubleClickDetector = op;
    }
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
