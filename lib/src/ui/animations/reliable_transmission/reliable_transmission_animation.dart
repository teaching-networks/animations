/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';
import 'dart:html';

import "package:angular/angular.dart";
import 'package:angular_components/angular_components.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/window/transmission_window.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/misc/description/description.component.dart';
import 'package:hm_animations/src/util/str/message.dart';

@Component(
  selector: "reliable-transmission-animation",
  templateUrl: "reliable_transmission_animation.html",
  styleUrls: const ["reliable_transmission_animation.css"],
  directives: const [
    coreDirectives,
    MaterialButtonComponent,
    MaterialIconComponent,
    MaterialToggleComponent,
    MaterialSliderComponent,
    CanvasComponent,
    DescriptionComponent,
  ],
  pipes: const [
    I18nPipe,
  ],
)
class ReliableTransmissionAnimation extends CanvasAnimation implements OnInit, OnDestroy, AfterViewChecked {
  /// Change detector reference.
  final ChangeDetectorRef _cd;

  /**
   * Sender and Receiver window for transmission.
   */
  TransmissionWindow transmissionWindow;

  @ViewChild("logcontainer", read: HtmlElement)
  HtmlElement logContainer;

  IdMessage<String> _senderLabel;
  IdMessage<String> _receiverLabel;

  I18nService _i18n;

  LanguageLoadedListener _languageChangedListener;

  /// Protocol to use
  ReliableTransmissionProtocol _protocol;

  @Input()
  AnimationDescriptor<dynamic> descriptor;

  List<String> logMessages = new List<String>();
  bool logChanged = false;
  StreamSubscription<String> _messageStreamSub;

  ReliableTransmissionAnimation(this._i18n, this._cd);

  @override
  ngOnInit() {
    _initTranslations();

    _listenToProtocolMessages(_protocol);

    transmissionWindow = new TransmissionWindow(senderLabel: _senderLabel, receiverLabel: _receiverLabel, protocol: _protocol, changeDetector: _cd);
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
    _i18n.removeLanguageLoadedListener(_languageChangedListener);
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

    _cd.markForCheck();
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
