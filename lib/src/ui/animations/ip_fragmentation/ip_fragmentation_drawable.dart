/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/animations/ip_fragmentation/fragment/ip_fragmentation_calculator.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/button/button_drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/text/input_drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/canvas_context_util.dart';
import 'package:hm_animations/src/ui/canvas/image/alignment/image_alignment.dart';
import 'package:hm_animations/src/ui/canvas/text/text_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/misc/image/image_info.dart';
import 'package:hm_animations/src/ui/misc/image/images.dart';

import 'fragment/ip_fragment.dart';

/// Drawable for the IP fragmentation animation.
class IPFragmentationDrawable extends Drawable {
  /// Allowed runes as input (only numeric).
  static const List<int> _allowedRunes = [48, 49, 50, 51, 52, 53, 54, 55, 56, 57];

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

  /// Button which will calculate the fragments when pressed.
  ButtonDrawable _calculateButton;

  /// Text drawable for the MTU label.
  TextDrawable _mtuText;

  /// Input for the datagram size to fragment.
  InputDrawable _datagramSizeInput;

  /// Input for maximum transmission unit.
  InputDrawable _mtuInput;

  /// Create drawable.
  IPFragmentationDrawable() {
    _init();
  }

  /// Initialize the IP fragmentation drawable.
  void _init() {
    _calculateButton = ButtonDrawable(
      parent: this,
      text: "Calculate",
      onClick: () => _recalculate(),
    );

    _mtuText = TextDrawable(
      parent: this,
      alignment: TextAlignment.RIGHT,
      text: "MTU",
    );

    _datagramSizeInput = InputDrawable(
      parent: this,
      value: "1500",
      maxLength: 5,
      width: 40 * window.devicePixelRatio,
      filter: (toInsert) => toInsert.runes.firstWhere((c) => !_allowedRunes.contains(c), orElse: () => -1) == -1,
    );

    _mtuInput = InputDrawable(
      parent: this,
      value: "576",
      maxLength: 5,
      width: 40 * window.devicePixelRatio,
      filter: (toInsert) => toInsert.runes.firstWhere((c) => !_allowedRunes.contains(c), orElse: () => -1) == -1,
    );

    _initImages();
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
    int mtu = int.tryParse(_mtuInput.value);
    int datagramSize = int.tryParse(_datagramSizeInput.value);

    if (mtu != null && datagramSize != null) {
      List<IPFragment> fragments = _calculator.fragment(datagramSize, mtu, 1);
      for (final f in fragments) {
        print(f);
      }
    }
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

    final clientBounds = drawImageOnCanvas(
      _clientImage,
      aspectRatio: _clientImageInfo.aspectRatio,
      width: imgWidth,
      height: size.height,
      alignment: ImageAlignment.START,
      mode: ImageDrawMode.FILL,
      x: 0,
    );

    final routerBounds = drawImageOnCanvas(
      _routerImage,
      aspectRatio: _routerImageInfo.aspectRatio,
      width: imgWidth,
      height: size.height,
      alignment: ImageAlignment.START,
      mode: ImageDrawMode.FILL,
      x: (size.width * 0.7 - imgWidth) / 2,
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
          max(
            clientBounds.top + clientBounds.height,
            routerBounds.top + routerBounds.height,
          ),
          serverBounds.top + serverBounds.height,
        );

    ctx.lineWidth = lineSize;
    setStrokeColor(Colors.LIGHTGREY);
    setFillColor(Colors.LIGHTGREY);

    _drawOffsetLine(clientBounds, yOffset, dotRadius);
    _drawOffsetLine(routerBounds, yOffset, dotRadius);
    _drawOffsetLine(serverBounds, yOffset, dotRadius);

    ctx.beginPath();
    ctx.moveTo(clientBounds.left + clientBounds.width / 2, yOffset);
    ctx.lineTo(serverBounds.left + serverBounds.width / 2, yOffset);
    ctx.stroke();

    double clientRouterMid = clientBounds.left + ((routerBounds.left + routerBounds.width / 2) - (clientBounds.left + clientBounds.width / 2)) / 2;
    double xOff = clientRouterMid - (_datagramSizeInput.size.width + _mtuText.size.width) / 2;
    _mtuText.render(ctx, lastPassTimestamp, x: xOff, y: yOffset);
    _datagramSizeInput.render(ctx, lastPassTimestamp, x: xOff + _mtuText.size.width, y: yOffset);

    double routerServerMid = routerBounds.left + ((serverBounds.left + serverBounds.width / 2) - (routerBounds.left + routerBounds.width / 2)) / 2;
    xOff = routerServerMid - (_mtuInput.size.width + _mtuText.size.width) / 2;
    _mtuText.render(ctx, lastPassTimestamp, x: xOff, y: yOffset);
    _mtuInput.render(ctx, lastPassTimestamp, x: xOff + _mtuText.size.width, y: yOffset);

    _calculateButton.render(ctx, lastPassTimestamp, x: 0, y: 0);
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
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update
  }
}
