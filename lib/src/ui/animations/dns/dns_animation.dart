import 'dart:html';
import 'package:hm_animations/src/ui/animations/dns/dns_query_type.dart';
import 'package:hm_animations/src/ui/animations/dns/dns_scenario.dart';
import 'package:tuple/tuple.dart';
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/shared/location_dot/location_dot.dart';
import 'package:hm_animations/src/ui/animations/shared/route/route_drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/progress/mutable_progress.dart';
import 'package:hm_animations/src/ui/canvas/shapes/bubble/bubble.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

@Component(
    selector: "dns-animation",
    styleUrls: ["dns_animation.css"],
    templateUrl: "dns_animation.html",
    directives: [coreDirectives, MaterialButtonComponent, MaterialIconComponent, MaterialDropdownSelectComponent, NgModel, CanvasComponent],
    pipes: [I18nPipe])
class DNSAnimation extends CanvasAnimation implements OnInit, OnDestroy {
  static final int _WRAP_BUBBLE_TEXT_AT = 20;

  /// Aspect ratio of the world map SVG -> width / height.
  static final double _MAP_ASPECT_RATIO = 1000 / 1360.0;

  final I18nService _i18n;

  /*
  IMAGES TO DRAW IN THE CANVAS.
   */
  final ImageElement _worldMap = new ImageElement(src: "img/animation/germany_map.svg");

  static final Point<double> _ORIGIN_LOCATION = Point(0.457, 0.21);
  LocationDot _originDot = LocationDot(color: Colors.SPACE_BLUE);
  Bubble _originBubble = Bubble("Requesting Host (Origin) / Local Name Server", _WRAP_BUBBLE_TEXT_AT);

  static final Point<double> _DESTINATION_LOCATION = Point(0.62, 0.88);
  LocationDot _destinationDot = LocationDot(color: Colors.TEAL);
  Bubble _destinationBubble = Bubble("Destination Host (hm.edu)", _WRAP_BUBBLE_TEXT_AT);

  static final Point<double> _ROOT_DNS_SERVER_LOCATION = Point(0.13, 0.48);
  LocationDot _rootDNSServerDot = LocationDot(color: Colors.LIME);
  Bubble _rootDNSServerBubble = Bubble("Root DNS Server", _WRAP_BUBBLE_TEXT_AT);

  static final Point<double> _INTERMEDIATE_DNS_SERVER_LOCATION = Point(0.82, 0.355);
  LocationDot _intermediateDNSServerDot = LocationDot(color: Colors.CORAL);
  Bubble _intermediateDNSServerBubble = Bubble("Intermediate DNS Server", _WRAP_BUBBLE_TEXT_AT);

  static final Point<double> _AUTHORITATIVE_DNS_SERVER_LOCATION = Point(0.315, 0.655);
  LocationDot _authoritativeDNSServerDot = LocationDot(color: Colors.BORDEAUX);
  Bubble _authoritativeDNSServerBubble = Bubble("Authoritative DNS Server", _WRAP_BUBBLE_TEXT_AT);

  MutableProgress _testProgress = MutableProgress();
  Duration _testDuration = Duration(seconds: 2);
  RouteDrawable _test;
  num _startTimestamp;

  List<Tuple3<Point<double>, LocationDot, Bubble>> _locationSource = List();

  List<DNSQueryType> _dnsQueryTypes;
  SelectionOptions<DNSQueryType> dnsQueryTypeOptions;
  SelectionModel<DNSQueryType> dnsQueryTypeSelectModel;
  static ItemRenderer<DNSQueryType> dnsQueryTypeItemRenderer = (dnsQueryType) => dnsQueryType.name.toString();

  List<DNSScenario> _scenarios;
  SelectionOptions<DNSScenario> scenarioOptions;
  SelectionModel<DNSScenario> scenarioSelectModel;
  static ItemRenderer<DNSScenario> scenarioItemRenderer = (scenario) => scenario.description.toString();

  DNSAnimation(this._i18n) {
    _test = RouteDrawable(_testProgress);

    _fillLocationSource();
  }

  void _fillLocationSource() {
    _locationSource.add(Tuple3(_ORIGIN_LOCATION, _originDot, _originBubble));
    _locationSource.add(Tuple3(_DESTINATION_LOCATION, _destinationDot, _destinationBubble));
    _locationSource.add(Tuple3(_ROOT_DNS_SERVER_LOCATION, _rootDNSServerDot, _rootDNSServerBubble));
    _locationSource.add(Tuple3(_INTERMEDIATE_DNS_SERVER_LOCATION, _intermediateDNSServerDot, _intermediateDNSServerBubble));
    _locationSource.add(Tuple3(_AUTHORITATIVE_DNS_SERVER_LOCATION, _authoritativeDNSServerDot, _authoritativeDNSServerBubble));
  }

  @override
  ngOnInit() {
    _initDNSQueryTypes();
    _initScenarios();
  }

  void _initDNSQueryTypes() {
    _dnsQueryTypes = List<DNSQueryType>();

    _dnsQueryTypes.add(IterativeDNSQueryType(_i18n.get("dns-animation.dns-query-type.iterative")));
    _dnsQueryTypes.add(RecursiveDNSQueryType(_i18n.get("dns-animation.dns-query-type.recursive")));

    dnsQueryTypeOptions = SelectionOptions.fromList(_dnsQueryTypes);
    dnsQueryTypeSelectModel = SelectionModel.single(selected: _dnsQueryTypes.first, keyProvider: (dnsQueryType) => dnsQueryType.id);
  }

  void _initScenarios() {
    _scenarios = List<DNSScenario>();

    _scenarios.add(DNSScenario(DNSScenarioType.ROOT_HAS_DESTINATION_CACHED, _i18n.get("dns-animation.scenario.root-has-destination-cached")));
    _scenarios.add(DNSScenario(DNSScenarioType.ROOT_HAS_INTERMEDIATE_CACHED, _i18n.get("dns-animation.scenario.root-has-intermediate-cached")));
    _scenarios.add(DNSScenario(DNSScenarioType.ROOT_HAS_AUTHORITATIVE_CACHED, _i18n.get("dns-animation.scenario.root-has-authoritative-cached")));
    _scenarios.add(DNSScenario(DNSScenarioType.LOCAL_HAS_DESTINATION_CACHED, _i18n.get("dns-animation.scenario.local-has-destination-cached")));

    scenarioOptions = SelectionOptions.fromList(_scenarios);
    scenarioSelectModel = SelectionModel.single(selected: _scenarios.first, keyProvider: (scenario) => scenario.type);
  }

  @override
  ngOnDestroy() {
    super.ngOnDestroy();
  }

  @override
  void render(num timestamp) {
    if (_startTimestamp == null) {
      _startTimestamp = timestamp;
    }

    _testProgress.progressSave = (timestamp - _startTimestamp) / _testDuration.inMilliseconds;

    context.clearRect(0, 0, size.width, size.height);

    // Draw map
    double mapHeight = size.height;
    double mapWidth = _MAP_ASPECT_RATIO * size.height;
    double mapXOffset = (size.width - mapWidth) / 2;

    context.drawImageScaled(_worldMap, mapXOffset, 0.0, mapWidth, mapHeight);

    // Replace relative locations with real ones.
    List<Tuple3<Point<double>, LocationDot, Bubble>> source = List();
    for (var tuple in _locationSource) {
      source.add(tuple.withItem1(_calculatePointOnMap(tuple.item1, mapXOffset, 0.0, mapWidth, mapHeight)));
    }

    // TODO Animated line from point to point (Maybe a curve, like planes would fly)
    setStrokeColor(context, Colors.SLATE_GREY);
    context.setLineDash([displayUnit, displayUnit / 2]);
    context.lineWidth = displayUnit / 3;
    _test.renderLine(context, source[0].item1, source[1].item1);

    _drawLocationDots(source, timestamp);
  }

  void _drawLocationDots(List<Tuple3<Point<double>, LocationDot, Bubble>> source, num timestamp) {
    double dotSize = displayUnit;

    // Draw dots
    for (var tuple in source) {
      var location = tuple.item1;
      var dot = tuple.item2;

      dot.render(context, Rectangle<double>(location.x, location.y, dotSize, dotSize), timestamp);
    }

    // Draw bubbles
    for (var tuple in source) {
      var location = tuple.item1;
      var bubble = tuple.item3;

      bubble.render(context, Rectangle<double>(location.x, location.y - dotSize * 1.5, dotSize, dotSize));
    }
  }

  Point<double> _calculatePointOnMap(Point<double> relativePoint, double mapXOffset, double mapYOffset, double mapWidth, double mapHeight) {
    return Point(mapXOffset + relativePoint.x * mapWidth, relativePoint.y * mapHeight);
  }

  int get canvasHeight => (windowHeight * 0.8).round();

  String get dnsQueryTypeSelectionLabel => dnsQueryTypeSelectModel.selectedValues.first.name.toString();
  String get scenarioSelectionLabel {
    String result = scenarioSelectModel.selectedValues.first.description.toString();

    if (result.length > 30) {
      result = "${result.substring(0, 30)}...";
    }

    return result;
  }
}
