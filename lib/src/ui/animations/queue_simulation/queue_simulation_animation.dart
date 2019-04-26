import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_ui.dart';
import 'package:hm_animations/src/ui/animations/queue_simulation/router/queue_router.dart';
import 'package:hm_animations/src/ui/animations/shared/packet_line/packet_line.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/misc/description/description.component.dart';

@Component(
  selector: "queue-simulation-animation",
  styleUrls: const ["queue_simulation_animation.css"],
  templateUrl: "queue_simulation_animation.html",
  directives: const [
    coreDirectives,
    MaterialButtonComponent,
    MaterialSliderComponent,
    MaterialIconComponent,
    CanvasComponent,
    DescriptionComponent,
  ],
  pipes: const [
    I18nPipe,
  ],
)
class QueueSimulationAnimation extends CanvasAnimation with AnimationUI implements OnDestroy {
  /// Proportions for the pre router line, router queue and post router line.
  static const List<double> COMPONENT_SIZE_PROPORTIONS = const <double>[0.3, 0.5, 0.20];

  PacketLine _preRouterLine;
  QueueRouter _queueRouter;
  PacketLine _postRouterLine;

  /// Emission rate of the packets in packets per second
  int emissionRate = 500;

  /// Transmission rate of the packets in packets per second
  int transmissionRate = 350;

  /// Length of the queue.
  int queueLength = 10;

  /// How many seconds are a second in the simulation.
  /// For example 100 is a scale of 1:100.
  int _secondScale = 500;

  /// Counter of dropped packets.
  int _droppedPackets = 0;

  /// Start timestamp of the simulation.
  num _startTimestamp;

  Random _rng = new Random();

  StreamSubscription _emitSubscription;
  StreamSubscription _processSubscription;

  I18nService _i18n;

  /// Translations.
  Message _incomingLabel;
  Message _queueOfRouterLabel;
  Message _droppedPacketsLabel;
  Message _timePassedLabel;
  Message _outgoingLabel;

  QueueSimulationAnimation(this._i18n) {
    reset();

    _loadTranslations();
  }

  void _loadTranslations() {
    _incomingLabel = _i18n.get("queue-simulation-animation.incoming");
    _queueOfRouterLabel = _i18n.get("queue-simulation-animation.queue-of-router");
    _droppedPacketsLabel = _i18n.get("queue-simulation-animation.dropped-packets");
    _timePassedLabel = _i18n.get("queue-simulation-animation.time-passed");
    _outgoingLabel = _i18n.get("queue-simulation-animation.outgoing");
  }

  void _emitLoop() {
    int baseMillis = (1000 * _secondScale / emissionRate).round();
    int randomizedMillis = (baseMillis / 2 + baseMillis * _rng.nextDouble()).round();
    _emitSubscription = new Future.delayed(new Duration(milliseconds: randomizedMillis)).asStream().listen((_) {
      _preRouterLine.emit(color: new Color.random());

      if (_emitSubscription != null) {
        _emitLoop();
      }
    });
  }

  void _processLoop() {
    _processSubscription = new Future.delayed(new Duration(milliseconds: (1000 * _secondScale / transmissionRate).round())).asStream().listen((_) {
      if (!_queueRouter.queueEmpty) {
        _postRouterLine.emit(color: _queueRouter.takeFromQueue().color);
      }

      if (_processSubscription != null) {
        _processLoop();
      }
    });
  }

  void onQueueLengthChange(int newLength) {
    queueLength = newLength;

    // Update router queue length
    _queueRouter.updateQueueLength(newLength);
  }

  void deregisterSubscriptions() {
    if (_emitSubscription != null) {
      _emitSubscription.cancel();
      _emitSubscription = null;
    }
    if (_processSubscription != null) {
      _processSubscription.cancel();
      _processSubscription = null;
    }
  }

  void reset() {
    deregisterSubscriptions();

    if (_postRouterLine == null && _queueRouter == null && _preRouterLine == null) {
      _postRouterLine = new PacketLine(duration: const Duration(seconds: 5));
      _queueRouter = new QueueRouter(queueLength);

      _preRouterLine = new PacketLine(
          duration: const Duration(seconds: 5),
          onArrival: (packetId, packetColor, forward, data) {
            if (!_queueRouter.addToQueue(color: packetColor)) {
              _droppedPackets++;
            }
          });
    } else {
      _postRouterLine.clear();
      _preRouterLine.clear();
      _queueRouter.clearQueue();
    }

    _emitLoop();
    _processLoop();

    _startTimestamp = window.performance.now();
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    double lineHeight = size.height / 10;
    double lineY = size.height / 2 - lineHeight / 2;
    double routerHeight = size.height / 5;
    double routerY = size.height / 2 - routerHeight / 2;

    double textPadding = 5 * window.devicePixelRatio;

    context.save();

    {
      context.textBaseline = "bottom";
      context.textAlign = "center";

      double width = size.width * COMPONENT_SIZE_PROPORTIONS[0];
      context.fillText(_incomingLabel.toString(), width / 2, lineY - (textPadding));
      _preRouterLine.render(context, new Rectangle<double>(0.0, lineY, width, lineHeight), timestamp);

      context.translate(width, 0.0);
      width = size.width * COMPONENT_SIZE_PROPORTIONS[1];

      context.save();
      {
        context.textAlign = "left";
        context.fillText(_queueOfRouterLabel.toString(), 0.0, routerY - (textPadding));

        context.textBaseline = "top";
        context.fillText("${_droppedPacketsLabel}: $_droppedPackets", 0.0, routerY + routerHeight + textPadding);

        context.fillText("${_timePassedLabel}: ${((timestamp - _startTimestamp) / _secondScale).floor()} ms", 0.0,
            routerY + routerHeight + textPadding * 2 + defaultFontSize);
      }
      context.restore();

      _queueRouter.render(context, new Rectangle<double>(0.0, routerY, width, routerHeight), timestamp);

      context.translate(width, 0.0);
      width = size.width * COMPONENT_SIZE_PROPORTIONS[2];
      context.fillText(_outgoingLabel.toString(), width / 2, lineY - (textPadding));
      _postRouterLine.render(context, new Rectangle<double>(0.0, lineY, width, lineHeight), timestamp);
    }

    context.restore();
  }

  @override
  ngOnDestroy() {
    super.ngOnDestroy();

    deregisterSubscriptions();
  }
}
