import 'dart:html';
import 'dart:math';
import "package:angular/angular.dart";
import 'package:angular_components/angular_components.dart';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_pipe.dart';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_service.dart';
import 'package:netzwerke_animationen/src/ui/canvas/animation/canvas_animation.dart';
import 'package:netzwerke_animationen/src/ui/canvas/canvas_component.dart';

@Component(
    selector: "transmission-animation",
    templateUrl: "transmission_animation.html",
    styleUrls: const ["transmission_animation.css"],
    directives: const [coreDirectives, materialDirectives, CanvasComponent],
    pipes: const [I18nPipe])
class TransmissionAnimation extends CanvasAnimation implements OnInit {
  /**
   * Propagation speed on the connection.
   */
  static const double PROPAGATION_SPEED = 2.1E+8;

  /**
   * How many times slower the simulation is compared to real time.
   */
  static const int SLOW_DOWN_SCALE = 5000;

  /*
  LENGTH INPUT CONTROL PROPERTIES
   */
  static const Map<String, int> _lengthUnits = const <String, int>{"km": 1000, "m": 1};
  SelectionModel<String> lengthSelectModel = new SelectionModel.single(selected: _lengthUnits.keys.first, keyProvider: (unit) => unit);
  SelectionOptions<String> lengthOptions = new SelectionOptions.fromList(_lengthUnits.keys.toList(), label: "Length Units");

  static const List<String> _lengthSuggestions = const <String>["10", "100", "1000"];
  String lengthValue;

  /*
  RATE INPUT CONTROL PROPERTIES
   */
  static const Map<String, int> _rateUnits = const <String, int>{"Mb/s": 1000 * 1000, "kb/s": 1000};
  SelectionModel<String> rateSelectModel = new SelectionModel.single(selected: _rateUnits.keys.first, keyProvider: (unit) => unit);
  SelectionOptions<String> rateOptions = new SelectionOptions.fromList(_rateUnits.keys.toList(), label: "Speed Units");

  static const List<String> _rateSuggestions = const <String>["1", "10", "32", "64", "100", "128", "256", "512", "1024"];
  String rateValue;

  /*
  PACKET SIZE INPUT CONTROL PROPERTIES
   */
  static const Map<String, int> _sizeUnits = const <String, int>{"Byte": 1, "kByte": 1000, "MByte": 1000 * 1000, "GByte": 1000 * 1000 * 1000};
  SelectionModel<String> sizeSelectModel = new SelectionModel.single(selected: _sizeUnits.keys.first, keyProvider: (unit) => unit);
  SelectionOptions<String> sizeOptions = new SelectionOptions.fromList(_sizeUnits.keys.toList(), label: "Size Units");

  static const List<String> _sizeSuggestions = const <String>["1", "10", "32", "64", "100", "128", "256", "512", "1024"];
  String packetSizeValue;

  /*
  IMAGES TO DRAW IN THE CANVAS.
   */
  ImageElement computer = new ImageElement(src: "img/computer.svg", width: 415, height: 290);

  /**
   * Whether to send a packet (Do the animation).
   */
  bool sendPacket = false;

  /**
   * Packet width in percent of the connection length.
   */
  double packetW = 0.0;

  /**
   * Total time the transmission takes (in seconds)
   */
  double totalTime = 0.0;

  /**
   * When the animation started.
   */
  double startTimestamp = 0.0;

  double time = 0.0;

  I18nService _i18n;

  TransmissionAnimation(this._i18n) {
    reset();
  }

  String get defaultPacketSize => _sizeSuggestions[4];

  String get defaultRate => _rateSuggestions[0];

  String get defaultLength => _lengthSuggestions[2];

  String get rateLabel => rateSelectModel.selectedValues.first;

  String get sizeLabel => sizeSelectModel.selectedValues.first;

  String get lengthUnitLabel => lengthSelectModel.selectedValues.first;

  List<String> get lengthSuggestions => _lengthSuggestions;

  List<String> get rateSuggestions => _rateSuggestions;

  List<String> get sizeSuggestions => _sizeSuggestions;

  Message _senderMessage;
  Message _receiverMessage;
  Message _propagationSpeed;

  /**
   * Get set length of the connection (in meter).
   */
  int get length {
    int len = int.tryParse(lengthValue) ?? _lengthSuggestions[1];
    return len * _lengthUnits[lengthUnitLabel];
  }

  /**
   * Get rate of the transmission (in bit per second).
   */
  int get rate {
    int r = int.tryParse(rateValue) ?? _rateSuggestions[1];
    return r * _rateUnits[rateLabel];
  }

  /**
   * Get packet size (in bit).
   */
  int get packetSize {
    int s = int.tryParse(packetSizeValue) ?? _sizeSuggestions[4];
    return s * _sizeUnits[sizeLabel] * 8;
  }

  @override
  ngOnInit() {
    // Get translations used in render method.
    _senderMessage = _i18n.get("packetTransmission.sender");
    _receiverMessage = _i18n.get("packetTransmission.receiver");
    _propagationSpeed = _i18n.get("packetTransmission.propagationSpeed");
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    context.textBaseline = "top";

    int inset = 10;

    // Percent of the canvas height (For responsive display).
    double hUnit = size.height / 100;
    double wUnit = size.width / 100;

    // Draw sender and receiver
    double boxSize = wUnit * 10;
    double computerRatio = computer.width / computer.height;
    double computerHeight = boxSize / computerRatio;
    double yOffset = hUnit * 50 - computerHeight / 2;

    context.setFillColorRgb(0, 0, 255);
    context.drawImageScaled(computer, inset, yOffset, boxSize, computerHeight); // Sender box
    context.drawImageScaled(computer, size.width - inset - boxSize, yOffset, boxSize, computerHeight); // Receiver box

    context.setFillColorRgb(0, 0, 0);
    context.textAlign = "center";
    context.fillText(_senderMessage.toString(), inset + boxSize / 2, yOffset + computerHeight, boxSize - inset);
    context.fillText(_receiverMessage.toString(), size.width - inset - boxSize / 2, yOffset + computerHeight, boxSize - inset);

    // Draw line.
    double lineHeight = hUnit * 3;
    double xOffset = inset + boxSize + 5;
    yOffset = hUnit * 50 - lineHeight / 2;
    double w = size.width - (inset + boxSize) * 2 - 10;
    context.setFillColorRgb(245, 245, 245);
    context.fillRect(xOffset, yOffset, w, lineHeight);

    // Draw propagation speed text.
    context.setFillColorRgb(0, 0, 0);
    context.fillText("${_propagationSpeed.toString()}: 2.1 x 10^8 m/s", size.width / 2, yOffset + lineHeight + 10);

    // Draw packet.
    double progress = ((timestamp - startTimestamp) / 1000) / (totalTime * SLOW_DOWN_SCALE);
    if (sendPacket) {
      if (progress < 1.0) {
        time = progress * totalTime * 1000;

        context.setFillColorRgb(204, 102, 102);

        // Transform progress interval [0.0; 1.0] to real interval [0.0 - packetW; 1.0]
        double packetX = -packetW + (1 + packetW) * progress;

        double leftBound = xOffset + max(0.0, packetX) * w;
        double rightBound = xOffset + min(packetX + packetW, 1.0) * w;

        context.fillRect(leftBound, yOffset, rightBound - leftBound, lineHeight);
      } else {
        time = totalTime * 1000;
        sendPacket = false;
      }
    }

    // Draw time.
    context.textBaseline = "bottom";
    context.fillText("${time.toStringAsFixed(3)} ms", size.width / 2, yOffset - lineHeight);
  }

  /**
   * Start the animation.
   */
  void start() {
    // Get settings.
    int length = this.length; // m
    int rate = this.rate; // bit/s
    int size = this.packetSize; // bit

    totalTime = size / rate + length / PROPAGATION_SPEED;

    // Init packet properties.
    packetW = ((size / rate) * PROPAGATION_SPEED) / length; // Packet width in percent of the connection length.

    startTimestamp = window.performance.now();

    sendPacket = true;
  }

  /**
   * Reset the animation.
   */
  void reset() {
    sendPacket = false;

    lengthValue = defaultLength;
    rateValue = defaultRate;
    packetSizeValue = defaultPacketSize;
  }
}
