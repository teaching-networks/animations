import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http/connection_type/connection_step.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http/connection_type/non_persistent_http_connection.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http/connection_type/persistent_http_connection.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http/http_connection_configuration.dart';
import 'package:hm_animations/src/ui/animations/shared/round_trip/client_server_round_trip.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/progress/mutable_progress.dart';
import 'package:hm_animations/src/ui/canvas/progress/progress.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

@Component(
  selector: "http-delay-animation",
  styleUrls: ["http_delay_animation.css"],
  templateUrl: "http_delay_animation.html",
  directives: [
    coreDirectives,
    MaterialButtonComponent,
    MaterialSliderComponent,
    MaterialToggleComponent,
    MaterialIconComponent,
    MaterialCheckboxComponent,
    MaterialIconTooltipComponent,
    CanvasComponent
  ],
  pipes: [I18nPipe]
)
class HttpDelayAnimation extends CanvasAnimation implements OnDestroy {

  static const double TEXT_PADDING = 10.0;

  MutableProgress progress;

  NonPersistentHttpConnection nonPersistentHttpConnection = NonPersistentHttpConnection();
  PersistentHttpConnection persistentHttpConnection = PersistentHttpConnection();

  num startTimestamp;

  List<ClientServerRoundTrip> roundTrips = List<ClientServerRoundTrip>();
  List<ConnectionStep> steps;
  int currentStepIndex = -1;

  StreamSubscription<double> _progressStreamSubscription;

  I18nService _i18n;

  List<Message> _connectionStepLabels;

  double maxLabelWidth;

  /// Whether the animation should be played or just fast forwarded.
  bool enableAnimation = true;

  bool isPersistentConnection = false;
  double transmissionDelay = 0.25;
  int numberOfObjects = 1;
  int parallelConnections = 1;
  bool usePipelining = false;
  int roundTripTime = 1000;

  double rttCount;

  HttpConnectionConfiguration config;

  Message _infoLabel;

  HttpDelayAnimation(this._i18n) {
    initTranslations();
  }
  
  void initTranslations() {
    _connectionStepLabels = new List<Message>();
    
    for (int i = 0; i < ConnectionStep.values.length; i++) {
      _connectionStepLabels.add(_i18n.get("http-delay-animation.connection-step.$i"));
    }

    _infoLabel = _i18n.get("http-delay-animation.info");
  }
  
  @override
  ngOnDestroy() {
    super.ngOnDestroy();
  }

  @override
  void render(num timestamp) {
    context.textBaseline = "middle";
    context.clearRect(0, 0, size.width, size.height);
    
    if (roundTrips.isNotEmpty) {
      context.textAlign = "left";

      if (maxLabelWidth == null && _connectionStepLabels != null) {
        calcMaxLabelWidth(context);
      }

      double rttHeight = size.height / rttCount;

      double stepWidth = size.width - maxLabelWidth - (2 * TEXT_PADDING * window.devicePixelRatio);

      double bigStepHeight = (config.objectTransmissionDelay + 1) * rttHeight;

      if (currentStepIndex != -1 && enableAnimation) {
        double rtt = isStepWithTransmission(steps[currentStepIndex]) ? 1 + config.objectTransmissionDelay : 1;
        progress.progressSave = (timestamp - startTimestamp) / (rtt * roundTripTime);
      }

      double heightCounter = 0.0;
      for (int i = 0; i < roundTrips.length; i++) {
        ClientServerRoundTrip roundTrip = roundTrips[i];

        double height = isStepWithTransmission(steps[i]) ? bigStepHeight : rttHeight;

        roundTrip.render(context, Rectangle(0.0, heightCounter, stepWidth, height));
        context.fillText(_connectionStepLabels[steps[i].index].toString(), stepWidth + (TEXT_PADDING * window.devicePixelRatio), heightCounter + height / 2);

        heightCounter += height;
      }
    } else {
      context.textAlign = "center";
      context.setFillColorRgb(240, 240, 240);
      context.fillRect(0.0, 0.0, size.width, size.height);

      context.setFillColorRgb(100, 100, 100);
      setFont(sizeFactor: 1.5, fontFamily: "Raleway");
      context.fillText(_infoLabel.toString(), size.width / 2, size.height / 2);
    }
  }

  double getRTTCount() {
    int smallSteps = 0;
    int bigSteps = 0;
    for (ConnectionStep step in steps) {
      if (isStepWithTransmission(step)) {
        bigSteps++;
      } else {
        smallSteps++;
      }
    }

    return (config.objectTransmissionDelay + 1) * bigSteps + smallSteps;
  }

  void calcMaxLabelWidth(CanvasRenderingContext2D context) {
    maxLabelWidth = 0.0;

    for (Message msg in _connectionStepLabels) {
      var width = context.measureText(msg.toString()).width;

      if (width > maxLabelWidth) {
        maxLabelWidth = width;
      }
    }
  }

  /// Build the animation with the current configuration.
  void build() {
    roundTrips.clear();
    currentStepIndex = -1;

    config = HttpConnectionConfiguration(
        objectCount: numberOfObjects,
        objectTransmissionDelay: transmissionDelay,
        parallelConnectionCount: parallelConnections,
        withPipelining: usePipelining
    );

    if (isPersistentConnection) {
      steps = persistentHttpConnection.generate(config);
    } else {
      steps = nonPersistentHttpConnection.generate(config);
    }

    rttCount = getRTTCount();

    nextStep();
  }

  /// Switch to next step.
  void nextStep() {
    if (steps.length > currentStepIndex + 1) {
      // If has next step:
      startTimestamp = window.performance.now();

      progress = MutableProgress(progress: enableAnimation ? 0.0 : 1.0);

      roundTrips.add(getRoundTripForStep(steps[++currentStepIndex], progress));

      if (enableAnimation) {
        _progressStreamSubscription = progress.progressChanges.listen((newProgress) {
          if (newProgress == 1.0) {
            _progressStreamSubscription.cancel();
            nextStep();
          }
        });
      } else {
        nextStep();
      }
    } else {
      currentStepIndex = -1;
    }
  }

  /// Get a round trip object for the passed [step].
  ClientServerRoundTrip getRoundTripForStep(ConnectionStep step, Progress p) {
    switch (step) {
      case ConnectionStep.TCP_CONNECTION_ESTABLISHMENT:
        return new ClientServerRoundTrip(p, Colors.TEAL, 0.0);
      case ConnectionStep.HTML_PAGE_REQUEST:
        return new ClientServerRoundTrip(p, Colors.LIME, config.objectTransmissionDelay);
      case ConnectionStep.OBJECT_REQUEST:
        return new ClientServerRoundTrip(p, Colors.CORAL, config.objectTransmissionDelay);
      default:
        throw new Exception("Step type not available: $step");
    }
  }

  bool isStepWithTransmission(ConnectionStep step) => step != ConnectionStep.TCP_CONNECTION_ESTABLISHMENT;

  int get canvasHeight => (windowHeight * 0.8).round();

  String get connectionTypeLabel => "Connection type";

}