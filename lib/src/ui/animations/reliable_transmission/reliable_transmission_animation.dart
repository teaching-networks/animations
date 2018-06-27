import 'dart:async';
import 'dart:html';

import "package:angular/angular.dart";
import 'package:angular_components/angular_components.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/window/transmission_window.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';

@Component(
    selector: "reliable-transmission-animation",
    templateUrl: "reliable_transmission_animation.html",
    styleUrls: const ["reliable_transmission_animation.css"],
    directives: const [coreDirectives, materialDirectives, CanvasComponent],
    pipes: const [I18nPipe])
class ReliableTransmissionAnimation extends CanvasAnimation implements OnInit, OnDestroy, AfterViewChecked {
  /**
   * Sender and Receiver window for transmission.
   */
  TransmissionWindow transmissionWindow;

  @ViewChild("logContainer")
  HtmlElement logContainer;

  Message _senderLabel;
  Message _receiverLabel;

  I18nService _i18n;

  LanguageChangedListener _languageChangedListener;

  /// Protocol to use
  ReliableTransmissionProtocol _protocol;

  @Input()
  Message description;

  List<String> logMessages = new List<String>();
  bool logChanged = false;
  StreamSubscription<String> _messageStreamSub;

  ReliableTransmissionAnimation(this._i18n);

  @override
  ngOnInit() {
    _initTranslations();

    _listenToProtocolMessages(_protocol);

    transmissionWindow = new TransmissionWindow(senderLabel: _senderLabel, receiverLabel: _receiverLabel, protocol: _protocol);
  }

  void _listenToProtocolMessages(ReliableTransmissionProtocol p) {
    if (_messageStreamSub != null) {
      _messageStreamSub.cancel();
    }

    _messageStreamSub = p.messageStream.listen((message) {
      logChanged = true;
      logMessages.add(message);
    });
  }

  void _initTranslations() {
    _senderLabel = _i18n.get("reliable-transmission-animation.sender");
    _receiverLabel = _i18n.get("reliable-transmission-animation.receiver");
  }

  @override
  ngOnDestroy() {
    super.ngOnDestroy();
    _i18n.removeLanguageChangedListener(_languageChangedListener);
  }

  void onCanvasClick(Point<double> pos) {
    transmissionWindow.onClick(pos);
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    transmissionWindow.render(context, toRect(0.0, 0.0, size), timestamp);
  }

  /// Check whether the current protocol is able to change the window size.
  bool get isWindowSizeChangeable => _protocol.canChangeWindowSize();

  /// Reset the animation.
  void reset() {
    transmissionWindow.reset();

    // Reset log messages.
    logMessages.clear();
  }

  @override
  void ngAfterViewChecked() {
    if (logChanged) {
      logChanged = false;
      // Scroll log container to bottom.
      logContainer.scrollTop = logContainer.scrollHeight;
    }
  }

  @Input()
  void set protocol(ReliableTransmissionProtocol protocol) {
    _protocol = protocol;
  }

  ReliableTransmissionProtocol get protocol => _protocol;

}
