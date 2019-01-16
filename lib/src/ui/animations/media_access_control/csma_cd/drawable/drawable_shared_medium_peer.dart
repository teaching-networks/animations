import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/drawable/drawable_shared_medium.dart';
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

  /// Random number generator.
  static Random _rng = Random();

  /// Icon of a host computer.
  static ImageElement _hostIcon = ImageElement(src: "img/animation/host_icon.svg");
  static const double _HOST_ICON_ASPECT_RATIO = 232.28 / 142.6;

  /// Id of the peer.
  final int id;

  /// Whether the drawable is currently highlighted.
  bool _highlighted = false;

  /// Actual bounds of the drawn peer.
  Rectangle<double> _actualBounds;

  /// Signal emitter to draw.
  List<VerticalSignalEmitter> _signalEmitter;

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

  /// Number of collisions since the last signal sending request.
  int _numberOfCollisions = 0;

  /// Whether peer is currently waiting for backoff time to expire.
  bool _isInBackoff = false;

  /// Whether to wait for a signal sending.
  bool _sendAwaited = false;

  /// Map for translations.
  final Map<String, Message> labelMap;

  /// When the after backoff signal should be sent.
  num _scheduledAfterBackoffSignalTimestamp;

  /// Timestamp from last render cycle.
  num _lastRenderTimestamp = -1;

  /// Create drawable peer.
  DrawableSharedMediumPeer({
    @required this.id,
    @required this.medium,
    @required this.position,
    @required this.labelMap,
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

    _drawHostIcon(context, rect);
    _drawPeerNumber(context, rect);
    _drawNotes(context, rect, _notes);

    context.restore();

    _actualBounds = rect;

    _lastRenderTimestamp = timestamp;
  }

  /// Draw an icon of a host.
  void _drawHostIcon(CanvasRenderingContext2D context, Rectangle<double> rect) {
    double iconWidth = rect.height * 0.85;
    double iconHeight = iconWidth / _HOST_ICON_ASPECT_RATIO;

    context.drawImageToRect(_hostIcon, Rectangle(rect.width / 2 - iconWidth / 2, rect.height / 2 - iconHeight / 2, iconWidth, iconHeight));
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
    Color color = isMediumOccupied() ? Colors.GREY : this.color;

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

  List<VerticalSignalEmitter> get signalEmitter => _signalEmitter;

  /// Add a signal emitter.
  void addSignalEmitter(VerticalSignalEmitter emitter) {
    if (_signalEmitter == null) {
      _signalEmitter = List<VerticalSignalEmitter>();
    }

    _signalEmitter.add(emitter);
  }

  /// Clear all signal emitter.
  void clearSignalEmitter() {
    _signalEmitter = null;
  }

  /// Set notes to show next to the peer.
  void setNotes(List<String> notes) => _notes = notes;

  /// Add a note to the shown notes next to the peer.
  void addNote(String note) => _notes != null ? _notes.add(note) : _notes = [note];

  /// Clear the notes shown next to the peer.
  void clearNotes() => _notes = null;

  /// Set mediums occupied state from the peers perception.
  void setMediumOccupied(bool occupied) {
    bool oldOccupied = isMediumOccupied();

    _mediumOccupied = occupied;

    if (oldOccupied != occupied) {
      _onOccupiedStateChanged(occupied);

      if (isSending() && occupied) {
        _onCollisionDetected();
      }
    }
  }

  /// Whether the medium is occupied from the peers perception.
  @override
  bool isMediumOccupied() => _mediumOccupied;

  @override
  SharedMedium getMedium() => medium;

  @override
  bool isListening() => _listening;

  @override
  void setListening(bool isListening) => _listening = isListening;

  @override
  bool isSending() => _isSending;

  @override
  void setSending(bool isSending) {
    _isSending = isSending;

    if (!_isSending) {
      _onSendEnd();
    }
  }

  /// What to do when the sending has ended.
  void _onSendEnd() {
    setListening(false);

    _numberOfCollisions = 0;
    _notes.clear();
  }

  /// What to do in case a collision has been detected.
  void _onCollisionDetected() {
    if (_isInBackoff) {
      return;
    }

    _isInBackoff = true;

    _numberOfCollisions++;

    final double backoffTime = medium is DrawableSharedMedium ? (medium as DrawableSharedMedium).calculateSignalDuration(512) : 1;
    int k = _rng.nextInt(pow(2, _numberOfCollisions));

    double totalBackoffTime = backoffTime * k;

    _abortSending();

    _scheduledAfterBackoffSignalTimestamp = window.performance.now() + totalBackoffTime * 1000;

    setNotes([
      labelMap["exponential-backoff"].toString(),
      "${labelMap["collisions"].toString()}: $_numberOfCollisions",
      "K: $k",
    ]);
  }

  void _abortSending() {
    if (_signalEmitter != null) {
      VerticalSignalEmitter emitter = _signalEmitter.last;

      emitter.cancelSignal(_lastRenderTimestamp);
    }
  }

  /// What to do in case the medium occupied state changes.
  void _onOccupiedStateChanged(bool isNowOccupied) {
    if (!isNowOccupied) {
      if ((!this.isSending() || (_isInBackoff && _sendAwaited)) && this.isListening()) {
        // Peer is listening because he wants to send a signal but could not in the past -> send signal now.
        if (medium is DrawableSharedMedium) {
          if ((medium as DrawableSharedMedium).sendSignal(this) && _isInBackoff) {
            _sendAwaited = false;
            _isInBackoff = false;
          }
        }
      }
    }
  }

  /// Whether peer currently waits for backoff time to expire.
  bool get isInBackoff => _isInBackoff;

  void afterRender() {
    if (_scheduledAfterBackoffSignalTimestamp != null && _lastRenderTimestamp >= _scheduledAfterBackoffSignalTimestamp) {
      _scheduledAfterBackoffSignalTimestamp = null;

      if (isMediumOccupied()) {
        _sendAwaited = true;
      } else {
        if (medium is DrawableSharedMedium) {
          if ((medium as DrawableSharedMedium).sendSignal(this)) {
            _isInBackoff = false;
          }
        }
      }
    }
  }
}
