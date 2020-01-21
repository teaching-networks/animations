/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/ip_fragmentation/fragment/ip_fragmentation_calculator.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/horizontal_alignment.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/vertical_layout.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/extension/mouse_listener.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/button/button_drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/text/input_drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/anim/anim.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/anim/anim_helper.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/canvas_context_util.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/image/alignment/image_alignment.dart';
import 'package:hm_animations/src/ui/canvas/shapes/bubble/bubble_container.dart';
import 'package:hm_animations/src/ui/canvas/text/alignment.dart';
import 'package:hm_animations/src/ui/canvas/text/text_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/canvas/util/curves.dart';
import 'package:hm_animations/src/ui/misc/image/image_info.dart';
import 'package:hm_animations/src/ui/misc/image/images.dart';

import 'fragment/ip_fragment.dart';

/// Drawable for the IP fragmentation animation.
class IPFragmentationDrawable extends Drawable implements MouseListener {
  /// Allowed runes as input (only numeric).
  static const List<int> _allowedRunes = [48, 49, 50, 51, 52, 53, 54, 55, 56, 57];

  /// The default MTU (Maximum transmission unit).
  static const int _defaultMTU = 576;

  /// The default datagram size.
  static const int _defaultDatagramSize = 1500;

  /// Service to get translations from.
  final I18nService _i18n;

  /// Image info of the server image.
  ImageInfo _serverImageInfo = Images.serverImage;

  /// Image info of the client image.
  ImageInfo _clientImageInfo = Images.hostIconImage;

  /// Image info of the router image.
  ImageInfo _routerImageInfo = Images.routerIconImage;

  /// Image source of the server image.
  CanvasImageSource _serverImage;

  /// Image source of the client image.
  CanvasImageSource _clientImage;

  /// Image source of the router image.
  CanvasImageSource _routerImage;

  /// Whether images have been loaded.
  bool _imagesLoaded = false;

  /// Calculator for the IP fragmentation.
  IPFragmentationCalculator _calculator = IPFragmentationCalculator();

  /// Text drawable for the MTU label.
  TextDrawable _mtuText;

  /// Input for the datagram size to fragment.
  InputDrawable _datagramSizeInput;

  /// Input for maximum transmission unit.
  InputDrawable _mtuInput;

  /// Current fragments to display.
  List<IPFragment> _fragments;

  double _renderedFragmentYStart = -1;
  double _renderedFragmentYEnd = -1;
  double _renderedFragmentXStart = -1;
  double _renderedFragmentXEnd = -1;
  double _renderedFragmentWidth = 0;

  /// The currently hovered fragment.
  IPFragment _hoveredFragment;

  TextDrawable _fragmentNumberDrawable;
  TextDrawable _fragmentSizeDrawable;
  TextDrawable _fragmentOffsetDrawable;
  TextDrawable _fragmentFlagDrawable;

  int _currentMTU = _defaultMTU;
  int _currentDatagramSize = _defaultDatagramSize;

  TextDrawable _errorTextDrawable;
  bool _showError = false;

  Message _mtuMsg;
  Message _rangeErrorMsg;
  Message _fragmentMsg;
  Message _sizeMsg;
  Message _offsetMsg;
  Message _moreFragmentsFlagMsg;
  Message _hoverItemInfoMsg;

  LanguageLoadedListener _languageLoadedListener;

  BubbleContainer _infoBubble;
  TextDrawable _infoBubbleText;

  Anim _backgroundFadeAnim;

  bool _infoShown = true;

  /// Create drawable.
  IPFragmentationDrawable(this._i18n) {
    _init();
  }

  /// Initialize the IP fragmentation drawable.
  void _init() {
    _mtuText = TextDrawable(
      parent: this,
      alignment: TextAlignment.RIGHT,
      text: _mtuMsg.toString(),
    );

    _datagramSizeInput = InputDrawable(
      parent: this,
      value: _defaultDatagramSize.toString(),
      maxLength: 5,
      width: 50 * window.devicePixelRatio,
      filter: (toInsert) => toInsert.runes.firstWhere((c) => !_allowedRunes.contains(c), orElse: () => -1) == -1,
      onChange: (value) {
        int number = int.tryParse(value);

        if (number != null && number >= IPFragmentationCalculator.minDatagramSize && number <= IPFragmentationCalculator.maxDatagramSize) {
          _currentDatagramSize = number;
          _recalculate();
          _showError = false;
        } else {
          _showError = true;
          _errorTextDrawable.text =
              _rangeErrorMsg.toString() + "[${IPFragmentationCalculator.minDatagramSize}; ${IPFragmentationCalculator.maxDatagramSize}]";
        }
      },
    );

    _mtuInput = InputDrawable(
      parent: this,
      value: _defaultMTU.toString(),
      maxLength: 5,
      width: 50 * window.devicePixelRatio,
      filter: (toInsert) => toInsert.runes.firstWhere((c) => !_allowedRunes.contains(c), orElse: () => -1) == -1,
      onChange: (value) {
        int number = int.tryParse(value);

        if (number != null && number >= IPFragmentationCalculator.minMTU && number <= IPFragmentationCalculator.maxMTU) {
          _currentMTU = number;
          _recalculate();
          _showError = false;
        } else {
          _showError = true;
          _errorTextDrawable.text =
              _rangeErrorMsg.toString() + "[${IPFragmentationCalculator.minMTU}; ${IPFragmentationCalculator.maxMTU}]";
        }
      },
    );

    _fragmentNumberDrawable = TextDrawable(
      parent: this,
      alignment: TextAlignment.CENTER,
    );

    _fragmentSizeDrawable = TextDrawable(
      parent: this,
      alignment: TextAlignment.CENTER,
    );

    _fragmentOffsetDrawable = TextDrawable(
      parent: this,
      alignment: TextAlignment.CENTER,
    );

    _fragmentFlagDrawable = TextDrawable(
      parent: this,
      alignment: TextAlignment.CENTER,
    );

    _errorTextDrawable = TextDrawable(
      parent: this,
      alignment: TextAlignment.CENTER,
      color: Colors.RED,
    );

    _infoBubbleText = TextDrawable(
      text: _hoverItemInfoMsg.toString(),
      color: Colors.WHITE,
      wrapAtLength: 30,
    );
    _infoBubble = BubbleContainer(
      parent: this,
      drawable: _infoBubbleText,
    )..color = Color.opacity(Colors.BLACK, 0.6);

    _backgroundFadeAnim = AnimHelper(
      duration: Duration(seconds: 1),
      curve: Curves.easeOutCubic,
      onEnd: (ts) {
        _infoShown = false;
      },
    );

    _initImages();
    _initTranslations();
  }

  @override
  void cleanup() {
    if (_languageLoadedListener != null) {
      _i18n.removeLanguageLoadedListener(_languageLoadedListener);
    }

    super.cleanup();
  }

  void _initTranslations() {
    _mtuMsg = _i18n.get("ip-frag.mtu");
    _rangeErrorMsg = _i18n.get("ip-frag.range-error");
    _fragmentMsg = _i18n.get("ip-frag.fragment-info.fragment");
    _sizeMsg = _i18n.get("ip-frag.fragment-info.size");
    _offsetMsg = _i18n.get("ip-frag.fragment-info.offset");
    _moreFragmentsFlagMsg = _i18n.get("ip-frag.fragment-info.more-fragments-flag");
    _hoverItemInfoMsg = _i18n.get("ip-frag.fragment-info.hover-item-info");

    _languageLoadedListener = (_) {
      _mtuText.text = _mtuMsg.toString();
      _infoBubbleText.text = _hoverItemInfoMsg.toString();

      invalidate();
    };
    _i18n.addLanguageLoadedListener(_languageLoadedListener);
    _languageLoadedListener(null);
  }

  /// Initialize all needed images.
  Future<void> _initImages() async {
    _serverImage = await _serverImageInfo.load();
    _clientImage = await _clientImageInfo.load();
    _routerImage = await _routerImageInfo.load();

    _imagesLoaded = true;
    invalidate();
  }

  /// Recalculate the fragments.
  void _recalculate() {
    if (_currentDatagramSize != null && _currentMTU != null) {
      _fragments = _calculator.fragment(_currentDatagramSize, _currentMTU, 1);
    }

    invalidate();
  }

  @override
  void draw() {
    if (!_imagesLoaded) {
      return;
    }

    double offsetSize = 30 * window.devicePixelRatio;
    double lineSize = 3 * window.devicePixelRatio;
    double dotRadius = 6 * window.devicePixelRatio;
    double imgWidth = size.width / 12;
    double packetHeight = 20 * window.devicePixelRatio;
    double textFieldOffset = packetHeight / 2 + 10 * window.devicePixelRatio;
    double fragmentSpacePadding = 20 * window.devicePixelRatio;

    final clientBounds = drawImageOnCanvas(
      _clientImage,
      aspectRatio: _clientImageInfo.aspectRatio,
      width: imgWidth,
      height: size.height,
      alignment: ImageAlignment.START,
      mode: ImageDrawMode.FILL,
      x: 0,
    );

    final serverBounds = drawImageOnCanvas(
      _serverImage,
      aspectRatio: _serverImageInfo.aspectRatio,
      width: imgWidth,
      height: size.height,
      alignment: ImageAlignment.START,
      mode: ImageDrawMode.FILL,
      x: size.width - imgWidth,
    );

    double yOffset = offsetSize +
        max(
          clientBounds.top + clientBounds.height,
          serverBounds.top + serverBounds.height,
        );

    final routerBounds = drawImageOnCanvas(
      _routerImage,
      aspectRatio: _routerImageInfo.aspectRatio,
      width: imgWidth,
      height: size.height,
      alignment: ImageAlignment.START,
      mode: ImageDrawMode.FILL,
      x: (size.width * 0.7 - imgWidth) / 2,
      y: yOffset - (imgWidth / _routerImageInfo.aspectRatio) / 2,
    );

    ctx.lineWidth = lineSize;
    setStrokeColor(Colors.LIGHTGREY);
    setFillColor(Colors.LIGHTGREY);

    _drawOffsetLine(clientBounds, yOffset, dotRadius);
    _drawOffsetLine(serverBounds, yOffset, dotRadius);

    ctx.beginPath();
    ctx.moveTo(clientBounds.left + clientBounds.width / 2, yOffset);
    ctx.lineTo(routerBounds.left, yOffset);
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(routerBounds.left + routerBounds.width, yOffset);
    ctx.lineTo(serverBounds.left + serverBounds.width / 2, yOffset);
    ctx.stroke();

    double clientRouterMid = ((clientBounds.left + clientBounds.width / 2) + routerBounds.left) / 2;
    double xOff = clientRouterMid - (_datagramSizeInput.size.width + _mtuText.size.width) / 2;
    _mtuText.render(ctx, lastPassTimestamp,
        x: xOff, y: yOffset + (_datagramSizeInput.size.height - _mtuText.size.height) / 2 + textFieldOffset);
    _datagramSizeInput.render(ctx, lastPassTimestamp, x: xOff + _mtuText.size.width, y: yOffset + textFieldOffset);

    _drawPacket(clientRouterMid, yOffset, imgWidth, packetHeight, Colors.SPACE_BLUE);

    double routerServerMid = ((routerBounds.left + routerBounds.width) + (serverBounds.left + serverBounds.width / 2)) / 2;
    xOff = routerServerMid - (_mtuInput.size.width + _mtuText.size.width) / 2;
    _mtuText.render(ctx, lastPassTimestamp, x: xOff, y: yOffset + (_mtuInput.size.height - _mtuText.size.height) / 2 + textFieldOffset);
    _mtuInput.render(ctx, lastPassTimestamp, x: xOff + _mtuText.size.width, y: yOffset + textFieldOffset);

    // Draw fragmented packets
    double totalFragmentSpace =
        (serverBounds.left + serverBounds.width / 2) - (routerBounds.left + routerBounds.width) - fragmentSpacePadding * 2;
    if (_fragments != null && _fragments.isNotEmpty) {
      double totalWidthPerFragment = totalFragmentSpace / _fragments.length;
      double fragmentDividerSize = max(totalWidthPerFragment * 0.05, window.devicePixelRatio);
      double widthPerFragment = totalWidthPerFragment - fragmentDividerSize;

      double curX = (routerBounds.left + routerBounds.width) + fragmentSpacePadding;

      _renderedFragmentWidth = totalWidthPerFragment;
      _renderedFragmentXStart = curX;
      _renderedFragmentXEnd = _renderedFragmentXStart + totalFragmentSpace;
      _renderedFragmentYStart = yOffset - packetHeight / 2;
      _renderedFragmentYEnd = _renderedFragmentYStart + packetHeight;

      bool isFirst = true;
      double firstXOff = curX + totalWidthPerFragment / 2;
      double firstYOff = yOffset;
      for (final fragment in _fragments) {
        _drawPacket(curX + totalWidthPerFragment / 2, yOffset, widthPerFragment, packetHeight,
            fragment == _hoveredFragment ? Colors.SPACE_BLUE : Colors.SLATE_GREY);

        curX += widthPerFragment + fragmentDividerSize;

        if (isFirst) isFirst = false;
      }

      if (_infoShown) {
        setFillColor(Color.opacity(Colors.BLACK, 0.2 - _backgroundFadeAnim.progress * 0.2));
        ctx.fillRect(0, 0, size.width, size.height);

        if (_infoBubble != null) {
          _infoBubble.render(ctx, lastPassTimestamp, x: firstXOff, y: firstYOff - packetHeight / 2);
        }
      }
    }

    if (_hoveredFragment != null) {
      _drawFragmentInfo(_hoveredFragment, routerServerMid, yOffset - textFieldOffset);
    }

    if (_showError) {
      _errorTextDrawable.render(ctx, lastPassTimestamp,
          x: (size.width - _errorTextDrawable.size.width) / 2,
          y: yOffset + textFieldOffset + _datagramSizeInput.size.height + textFieldOffset);
    }
  }

  void _drawFragmentInfo(IPFragment fragment, double xMid, double yBottom) {
    double curY = yBottom;

    _fragmentFlagDrawable.render(ctx, lastPassTimestamp,
        x: xMid - _fragmentFlagDrawable.size.width / 2, y: curY - _fragmentFlagDrawable.size.height);
    curY -= _fragmentFlagDrawable.size.height;

    _fragmentOffsetDrawable.render(ctx, lastPassTimestamp,
        x: xMid - _fragmentOffsetDrawable.size.width / 2, y: curY - _fragmentOffsetDrawable.size.height);
    curY -= _fragmentOffsetDrawable.size.height;

    _fragmentSizeDrawable.render(ctx, lastPassTimestamp,
        x: xMid - _fragmentSizeDrawable.size.width / 2, y: curY - _fragmentSizeDrawable.size.height);
    curY -= _fragmentSizeDrawable.size.height;

    _fragmentNumberDrawable.render(ctx, lastPassTimestamp,
        x: xMid - _fragmentNumberDrawable.size.width / 2, y: curY - _fragmentNumberDrawable.size.height);
  }

  void _drawPacket(double x, double y, double width, double height, Color color) {
    setFillColor(color);
    ctx.fillRect(x - width / 2, y - height / 2, width, height);
  }

  void _drawOffsetLine(Rectangle<double> bounds, double yOffset, double radius) {
    double xMid = bounds.left + bounds.width / 2;

    ctx.beginPath();
    ctx.moveTo(xMid, bounds.top + bounds.height);
    ctx.lineTo(xMid, yOffset);
    ctx.stroke();

    ctx.beginPath();
    ctx.ellipse(xMid, yOffset, radius, radius, 2 * pi, 0, 2 * pi, false);
    ctx.fill();
  }

  @override
  bool needsRepaint() => _backgroundFadeAnim.running;

  @override
  void update(num timestamp) {
    _backgroundFadeAnim.update(timestamp);
  }

  @override
  void onMouseDown(CanvasMouseEvent event) {
    // Do nothing
  }

  @override
  void onMouseMove(CanvasMouseEvent event) {
    if (!containsPos(event.pos) || _fragments == null || _fragments.isEmpty) {
      _onLeaveFragment();
      return;
    }

    bool isInFragmentSpace = event.pos.x >= _renderedFragmentXStart &&
        event.pos.x <= _renderedFragmentXEnd &&
        event.pos.y >= _renderedFragmentYStart &&
        event.pos.y <= _renderedFragmentYEnd;
    if (!isInFragmentSpace) {
      _onLeaveFragment();
      return;
    }

    double xOffset = event.pos.x - _renderedFragmentXStart;
    int fragmentIndex = xOffset ~/ _renderedFragmentWidth;

    if (fragmentIndex < _fragments.length) {
      _onHoverFragment(_fragments[fragmentIndex]);
    }
  }

  void _onLeaveFragment() {
    _hoveredFragment = null;

    invalidate();
  }

  void _onHoverFragment(IPFragment fragment) {
    if (_hoveredFragment == fragment) {
      return;
    }
    _hoveredFragment = fragment;

    if (_infoShown && !_backgroundFadeAnim.running) {
      _backgroundFadeAnim.start();
      _infoBubble = null;
    }

    _fragmentNumberDrawable.text = "${_fragmentMsg.toString()} ${fragment.number}";
    _fragmentSizeDrawable.text = "${_sizeMsg.toString()}: ${fragment.size} bytes";
    _fragmentOffsetDrawable.text = "${_offsetMsg.toString()}: ${fragment.offset}";
    _fragmentFlagDrawable.text = "${_moreFragmentsFlagMsg.toString()}: ${fragment.moreFragments ? 1 : 0}";

    invalidate();
  }

  @override
  void onMouseUp(CanvasMouseEvent event) {
    // Do nothing
  }
}
