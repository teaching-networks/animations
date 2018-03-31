import 'dart:html';
import "package:angular/angular.dart";
import 'package:angular_components/angular_components.dart';
import 'package:netzwerke_animationen/src/ui/animations/animation_descriptor.dart';
import 'package:netzwerke_animationen/src/ui/canvas/animation/canvas_animation.dart';
import 'package:netzwerke_animationen/src/ui/canvas/canvas_component.dart';

@Component(
  selector: "transmission-animation",
  templateUrl: "transmission_animation.html",
  styleUrls: const ["transmission_animation.css"],
  directives: const [CORE_DIRECTIVES, materialDirectives, CanvasComponent]
)
class TransmissionAnimation extends CanvasAnimation implements OnInit {

  static const AnimationDescriptor DESCRIPTOR = const AnimationDescriptor(TransmissionAnimation, "Packet Transmission", "/img/image-preview.png", "transmission");

  /*
  LENGTH INPUT CONTROL PROPERTIES
   */
  static const List<String> _lengthUnits = const <String>["m", "km"];
  SelectionModel<String> lengthSelectModel = new SelectionModel.withList(selectedValues: [_lengthUnits[1]]);
  SelectionOptions<String> lengthOptions = new SelectionOptions.fromList(_lengthUnits, label: "Length Units");

  static const List<String> _lengthSuggestions = const <String>["10", "100", "1000"];
  String lengthValue = _lengthSuggestions[1];

  /*
  RATE INPUT CONTROL PROPERTIES
   */
  static const List<String> _rateUnits = const <String>["kb/s", "Mb/s"];
  SelectionModel<String> rateSelectModel = new SelectionModel.withList(selectedValues: [_rateUnits[1]]);
  SelectionOptions<String> rateOptions = new SelectionOptions.fromList(_rateUnits, label: "Speed Units");

  static const List<String> _rateSuggestions = const <String>["1", "10", "32", "64", "100", "128", "256", "512", "1024"];
  String rateValue = _rateSuggestions[1];

  /*
  PACKET SIZE INPUT CONTROL PROPERTIES
   */
  static const List<String> _sizeUnits = const <String>["Byte", "kByte", "MByte", "GByte"];
  SelectionModel<String> sizeSelectModel = new SelectionModel.withList(selectedValues: [_sizeUnits[0]]);
  SelectionOptions<String> sizeOptions = new SelectionOptions.fromList(_sizeUnits, label: "Size Units");

  static const List<String> _sizeSuggestions = const <String>["1", "10", "32", "64", "100", "128", "256", "512", "1024"];
  String sizeValue = _sizeSuggestions[4];

  /*
  IMAGES TO DRAW IN THE CANVAS.
   */
  ImageElement computer = new ImageElement(src: "/img/computer.png");

  double width = 0.0;
  double widthPerSecond = 10.0;

  num lastTimestamp = 0;

  @override
  ngOnInit() {
    // Do not allow deselects in selection dropdowns.
    ignoreDeselect(rateSelectModel);
    ignoreDeselect(sizeSelectModel);
  }

  void ignoreDeselect<T>(SelectionModel<T> model) {
    model.selectionChanges.listen((changes) {
      SelectionChangeRecord<T> change = changes[0];

      if (change.added.isEmpty) {
        // Entry has been deselected (We do not allow this) -> Undo this.
        model.select(change.removed.first);
      }
    });
  }

  @override
  void render(num timestamp) {
    context.setFillColorRgb(240, 240, 240);
    context.fillRect(0, 0, size.width, size.height);

    context.textBaseline = "middle";
    int fontSize = (size.height * 0.04).toInt();
    context.font = "${fontSize}px sans-serif";

    int inset = 10;

    // Percent of the canvas height (For responsive display).
    double hUnit = size.height / 100;
    double wUnit = size.width / 100;

    // Draw sender and receiver
    double boxSize = wUnit * 10;
    double yOffset = hUnit * 50 - boxSize / 2;

    context.setFillColorRgb(0, 0, 255);
    context.drawImageScaled(computer, inset, yOffset, boxSize, boxSize); // Sender box
    context.drawImageScaled(computer, size.width - inset - boxSize, yOffset, boxSize, boxSize); // Receiver box

    context.setFillColorRgb(0, 0, 0);
    context.fillText("Sender", inset, yOffset + boxSize, boxSize - inset);
    context.fillText("Receiver", size.width - inset - boxSize, yOffset + boxSize, boxSize - inset);

    // Draw line.
    double lineHeight = hUnit * 3;
    double xOffset = inset + boxSize;
    yOffset = hUnit * 50 - lineHeight / 2;
    double w = size.width - (inset + boxSize) * 2;
    context.setFillColorRgb(255, 255, 255);
    context.fillRect(xOffset, yOffset, w, lineHeight);

    // Draw packet.
    if (lastTimestamp != -1) {
      width += widthPerSecond * (timestamp - lastTimestamp) / 1000;
    }

    context.setFillColorRgb(204, 102, 102);
    context.fillRect(xOffset, yOffset, width, lineHeight);

    lastTimestamp = timestamp;
  }

  void start() {
    print("Start pressed");
  }

  void reset() {
    print("Reset pressed");
  }

  List<String> get lengthSuggestions {
    return _lengthSuggestions;
  }

  List<String> get rateSuggestions {
    return _rateSuggestions;
  }

  List<String> get sizeSuggestions {
    return _sizeSuggestions;
  }

  String get rateLabel => rateSelectModel.selectedValues.first;

  String get sizeLabel => sizeSelectModel.selectedValues.first;

  String get lengthUnitLabel => lengthSelectModel.selectedValues.first;

}