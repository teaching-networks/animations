import "dart:html";
import 'dart:math';
import "package:angular/angular.dart";
import 'package:angular_components/angular_components.dart';
import "package:netzwerke_animationen/src/canvas/animation/canvas_animation.dart";
import 'package:netzwerke_animationen/src/canvas/canvas_component.dart';

@Component(
  selector: "transmission-animation",
  templateUrl: "transmission_animation.html",
  styleUrls: const ["transmission_animation.css"],
  directives: const [CORE_DIRECTIVES, materialDirectives, CanvasComponent]
)
class TransmissionAnimation extends CanvasAnimation implements OnInit {

  /*
  LENGTH INPUT CONTROL PROPERTIES
   */
  static const List<String> _lengthSuggestions = const <String>["10", "100", "1000"];
  String lengthValue = _lengthSuggestions[1];

  /*
  RATE INPUT CONTROL PROPERTIES
   */
  static const List<String> _rateUnits = const <String>["kb/s", "Mb/s"];
  SelectionModel<String> rateSelectModel = new SelectionModel.withList(selectedValues: [_rateUnits[1]]);
  SelectionOptions<String> rateOptions = new SelectionOptions.fromList(_rateUnits, label: "Units");

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
    context.clearRect(0, 0, size.width, size.height);

    context.textBaseline = "top";
    context.font = "30px 'Roboto'";

    context.fillText("Way length: $lengthValue km", 10, 10, size.width - 20);
    context.fillText("Rate: $rateValue ${rateSelectModel.selectedValues.first}", 10, 50, size.width - 20);
    context.fillText("Packet size: $sizeValue ${sizeSelectModel.selectedValues.first}", 10, 90, size.width - 20);
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

}