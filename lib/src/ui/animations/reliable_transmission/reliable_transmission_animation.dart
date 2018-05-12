import 'dart:html';

import "package:angular/angular.dart";
import 'package:angular_components/angular_components.dart';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_pipe.dart';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_service.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/protocols/go_back_n_protocol.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/protocols/selective_repeat_protocol.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/protocols/stop_and_wait_protocol.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/transmission_window.dart';
import 'package:netzwerke_animationen/src/ui/canvas/animation/canvas_animation.dart';
import 'package:netzwerke_animationen/src/ui/canvas/canvas_component.dart';

@Component(
  selector: "reliable-transmission-animation",
  templateUrl: "reliable_transmission_animation.html",
  styleUrls: const ["reliable_transmission_animation.css"],
  directives: const [coreDirectives, materialDirectives, CanvasComponent],
  pipes: const [I18nPipe]
)
class ReliableTransmissionAnimation extends CanvasAnimation implements OnInit, OnDestroy {

  /**
   * List of protocols for reliable transmission.
   */
  static const List<ReliableTransmissionProtocol> PROTOCOLS = const <ReliableTransmissionProtocol>[
    const StopAndWaitProtocol("reliable-transmission-animation.protocol.stop-and-wait"),
    const GoBackNProtocol("reliable-transmission-animation.protocol.go-back-n"),
    const SelectiveRepeatProtocol("reliable-transmission-animation.protocol.selective-repeat")
  ];

  /**
   * Sender and Receiver window for transmission.
   */
  TransmissionWindow transmissionWindow;

  Message _senderLabel;
  Message _receiverLabel;

  I18nService _i18n;

  SelectionModel<ReliableTransmissionProtocol> protocolSelectModel = new SelectionModel.single(selected: PROTOCOLS.first);
  SelectionOptions<ReliableTransmissionProtocol> protocolSelectOptions = new SelectionOptions.fromList(PROTOCOLS);
  Map<String, String> _protocolNameLookup = new Map<String, String>();
  ItemRenderer<ReliableTransmissionProtocol> protocolSelectItemRenderer;
  String get protocolSelectLabel => protocolSelectItemRenderer(protocolSelectModel.selectedValues.first);

  LanguageChangedListener _languageChangedListener;

  ReliableTransmissionAnimation(this._i18n);

  @override
  ngOnInit() {
    _initTranslations();

    _languageChangedListener = (newLocale) {
      _protocolNameLookup.clear();

      _initTranslations();
    };

    _i18n.addLanguageChangedListener(_languageChangedListener);

    protocolSelectItemRenderer = (protocol) => _protocolNameLookup[protocol.nameKey];

    transmissionWindow = new TransmissionWindow(senderLabel: _senderLabel, receiverLabel: _receiverLabel);
  }

  void _initTranslations() {
    _senderLabel = _i18n.get("reliable-transmission-animation.sender");
    _receiverLabel = _i18n.get("reliable-transmission-animation.receiver");

    for (var protocol in PROTOCOLS) {
      _protocolNameLookup[protocol.nameKey] = _i18n.get(protocol.nameKey).toString();
    }
  }

  @override
  ngOnDestroy() {
    super.ngOnDestroy();
    _i18n.removeLanguageChangedListener(_languageChangedListener);
  }

  void onCanvasClick(Point<num> pos) {
    transmissionWindow.onClick(pos);
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    transmissionWindow.render(context, toRect(0.0, 0.0, size), timestamp);
  }

}