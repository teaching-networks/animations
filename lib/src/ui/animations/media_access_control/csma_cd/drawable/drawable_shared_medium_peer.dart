import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/drawable/signal_emitter/impl/vertical_signal_emitter.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/medium/shared_medium.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/peer/shared_medium_peer.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/edges.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/size_type.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:meta/meta.dart';

/// A Drawable shared medium peer.
class DrawableSharedMediumPeer extends CanvasDrawable implements SharedMediumPeer {
  /// Colors of the peers.
  static const List<Color> _peerColors = [
    Colors.ORANGE,
    Colors.BLUE_GRAY,
    Colors.PURPLE,
    Colors.SPACE_BLUE,
    Colors.NAVY,
  ];

  /// Id of the peer.
  final int id;

  /// Whether the drawable is currently highlighted.
  bool _highlighted = false;

  /// Actual bounds of the drawn peer.
  Rectangle<double> _actualBounds;

  /// Signal emitter to draw.
  VerticalSignalEmitter _signalEmitter;

  /// Position of the peer on the shared medium.
  final double position;

  /// Notes to show next to the peer.
  List<String> _notes;

  /// Color of the peer.
  final Color color;

  /// Round rectangle as background for the peer.
  final RoundRectangle _roundRectangle = RoundRectangle(
    color: Colors.SLATE_GREY,
    radiusSizeType: SizeType.PERCENT,
    paintMode: PaintMode.FILL,
    radius: Edges.all(1.0),
  );

  /// Medium the peer is sending and listening on.
  final SharedMedium medium;

  /// Whether the peer is listening to the medium.
  bool _listening = false;

  /// Whether from the peers perception the medium is currently occupied.
  bool _mediumOccupied = false;

  /// Whether the peer is currently sending.
  bool _isSending = false;

  /// Create drawable peer.
  DrawableSharedMediumPeer({
    @required this.id,
    @required this.medium,
    @required this.position,
  }) : color = DrawableSharedMediumPeer._peerColors.length > id ? DrawableSharedMediumPeer._peerColors[id] : Colors.SLATE_GREY;

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();

    context.translate(rect.left, rect.top);

    double size = rect.height;

    _roundRectangle.color = _getBackgroundColor();
    _roundRectangle.render(
        context,
        Rectangle(
          rect.width / 2 - size / 2,
          0,
          size,
          size,
        ));

    _drawPeerNumber(context, rect);
    _drawNotes(context, rect, _notes);

    context.restore();

    _actualBounds = rect;
  }

  /// Draw the number of the peer.
  void _drawPeerNumber(CanvasRenderingContext2D context, Rectangle<double> rect) {
    context.textAlign = "center";
    context.textBaseline = "middle";
    context.font = "${rect.height * 0.6}px 'Roboto'";

    double shadowOffset = window.devicePixelRatio * 2;
    setFillColor(context, Colors.DARK_GRAY);
    context.fillText((id + 1).toString(), rect.width / 2 + shadowOffset, rect.height / 2 + shadowOffset);
    setFillColor(context, Colors.WHITE);
    context.fillText((id + 1).toString(), rect.width / 2, rect.height / 2);
  }

  /// Draw notes next to the peer (if any).
  void _drawNotes(CanvasRenderingContext2D context, Rectangle<double> rect, List<String> notes) {
    if (notes == null || notes.isEmpty) {
      return;
    }

    double fontSize = defaultFontSize;

    context.textAlign = "right";
    context.textBaseline = "top";
    context.font = "${fontSize}px 'Roboto'";

    double lineHeight = fontSize * 1.2;
    double xPadding = window.devicePixelRatio * 20;

    double yMid = rect.height / 2;
    double xRight = rect.width / 2 - rect.height / 2 - xPadding;
    double yTop = yMid - (notes.length * lineHeight) / 2;

    setFillColor(context, Colors.DARK_GRAY);
    for (int i = 0; i < notes.length; i++) {
      context.fillText(notes[i], xRight, yTop + lineHeight * i);
    }
  }

  /// Get background color of peer.
  Color _getBackgroundColor() {
    Color color = isMediumOccupied() ? Colors.DARK_GRAY : this.color;

    if (_highlighted) {
      color = Color.brighten(color, 0.1);
    }

    return color;
  }

  /// Set whether the drawable should be highlighted.
  void setHighlighted(bool highlighted) => _highlighted = highlighted;

  /// Get the actual bounds of the drawn peer.
  Rectangle<double> getActualBounds() => _actualBounds;

  /// Set the drawables actual bounds.
  void setActualBounds(Rectangle<double> bounds) => _actualBounds = bounds;

  VerticalSignalEmitter get signalEmitter => _signalEmitter;

  set signalEmitter(VerticalSignalEmitter value) {
    _signalEmitter = value;
  }

  /// Set notes to show next to the peer.
  void setNotes(List<String> notes) => _notes = notes;

  /// Add a note to the shown notes next to the peer.
  void addNote(String note) => _notes != null ? _notes.add(note) : [note];

  /// Clear the notes shown next to the peer.
  void clearNotes() => _notes = null;

  /// Set mediums occupied state from the peers perception.
  void setMediumOccupied(bool occupied) {
    if (isMediumOccupied() != occupied) {
      // occupied state changed.

      if (isSending() && occupied) {
        onCollisionDetected();
      }
    }

    _mediumOccupied = occupied;
  }

  /// Whether the medium is occupied from the peers perception.
  @override
  bool isMediumOccupied() => _mediumOccupied;

  @override
  SharedMedium getMedium() => medium;

  @override
  bool isListening() => _listening;

  @override
  bool isSending() => _isSending;

  @override
  void onCollisionDetected() {
    // TODO: implement onCollisionDetected
  }

  @override
  void send() {
    // TODO: implement send
  }
}
