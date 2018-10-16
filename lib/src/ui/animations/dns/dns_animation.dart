import 'dart:async';
import 'dart:html';
import 'package:hm_animations/src/ui/animations/dns/dns_query_type.dart';
import 'package:hm_animations/src/ui/animations/dns/dns_scenario.dart';
import 'package:hm_animations/src/ui/animations/dns/dns_system/dns_query.dart';
import 'package:hm_animations/src/ui/animations/dns/dns_system/dns_query_mode.dart';
import 'package:hm_animations/src/ui/animations/dns/dns_system/dns_server.dart';
import 'package:hm_animations/src/ui/animations/dns/dns_system/dns_server_type.dart';
import 'package:hm_animations/src/ui/animations/dns/waypoint_route_drawable.dart';
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

  Duration _animationDurationPerLine = Duration(seconds: 1);
  List<WaypointRouteDrawable> _routeDrawables = List<WaypointRouteDrawable>();
  MutableProgress _currentProgress;
  StreamSubscription<double> _currentProgressListener;
  num _startTimestamp;
  List<Tuple3<DNSServerType, DNSServerType, bool>> _ways = new List();

  List<Tuple4<Point<double>, LocationDot, Bubble, DNSServerType>> _locationSource = List();

  List<DNSQueryType> _dnsQueryTypes;
  SelectionOptions<DNSQueryType> dnsQueryTypeOptions;
  SelectionModel<DNSQueryType> dnsQueryTypeSelectModel;
  static ItemRenderer<DNSQueryType> dnsQueryTypeItemRenderer = (dnsQueryType) => dnsQueryType.name.toString();

  List<DNSScenario> _scenarios;
  SelectionOptions<DNSScenario> scenarioOptions;
  SelectionModel<DNSScenario> scenarioSelectModel;
  static ItemRenderer<DNSScenario> scenarioItemRenderer = (scenario) => scenario.description.toString();

  DNSAnimation(this._i18n) {
    _fillLocationSource();
  }

  void _fillLocationSource() {
    _locationSource.add(Tuple4(_ORIGIN_LOCATION, _originDot, _originBubble, DNSServerType.LOCAL));
    _locationSource.add(Tuple4(_DESTINATION_LOCATION, _destinationDot, _destinationBubble, null));
    _locationSource.add(Tuple4(_ROOT_DNS_SERVER_LOCATION, _rootDNSServerDot, _rootDNSServerBubble, DNSServerType.ROOT));
    _locationSource.add(Tuple4(_INTERMEDIATE_DNS_SERVER_LOCATION, _intermediateDNSServerDot, _intermediateDNSServerBubble, DNSServerType.INTERMEDIATE));
    _locationSource.add(Tuple4(_AUTHORITATIVE_DNS_SERVER_LOCATION, _authoritativeDNSServerDot, _authoritativeDNSServerBubble, DNSServerType.AUTHORITATIVE));
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

    _scenarios.add(DNSScenario(_i18n.get("dns-animation.scenario.root-has-destination-cached"), [DNSServerType.ROOT]));
    _scenarios.add(DNSScenario(
        _i18n.get("dns-animation.scenario.root-has-intermediate-cached"), [DNSServerType.ROOT, DNSServerType.INTERMEDIATE, DNSServerType.AUTHORITATIVE]));
    _scenarios.add(DNSScenario(_i18n.get("dns-animation.scenario.root-has-authoritative-cached"), [DNSServerType.ROOT, DNSServerType.AUTHORITATIVE]));
    _scenarios.add(DNSScenario(_i18n.get("dns-animation.scenario.local-has-destination-cached"), []));

    scenarioOptions = SelectionOptions.fromList(_scenarios);
    scenarioSelectModel = SelectionModel.single(selected: _scenarios.first);
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

    context.clearRect(0, 0, size.width, size.height);

    // Draw map
    double mapHeight = size.height;
    double mapWidth = _MAP_ASPECT_RATIO * size.height;
    double mapXOffset = (size.width - mapWidth) / 2;

    context.drawImageScaled(_worldMap, mapXOffset, 0.0, mapWidth, mapHeight);

    // Replace relative locations with real ones.
    List<Tuple4<Point<double>, LocationDot, Bubble, DNSServerType>> source = List();
    Map<DNSServerType, Tuple4<Point<double>, LocationDot, Bubble, DNSServerType>> lookup = Map();
    for (var tuple in _locationSource) {
      var newTuple = tuple.withItem1(_calculatePointOnMap(tuple.item1, mapXOffset, 0.0, mapWidth, mapHeight));

      source.add(newTuple);
      lookup[tuple.item4] = newTuple;
    }

    if (_currentProgress != null) {
      _currentProgress.progressSave = (timestamp - _startTimestamp) / _animationDurationPerLine.inMilliseconds; // Animate
    }

    context.setLineDash([displayUnit, displayUnit / 2]);
    context.lineWidth = displayUnit / 3;
    for (var routeDrawable in _routeDrawables) {
      var startPoint = lookup[routeDrawable.start].item1;
      var endPoint = lookup[routeDrawable.end].item1;

      routeDrawable.renderLine(context, startPoint, endPoint);
    }

    _drawLocationDots(source, timestamp);
  }

  void _drawLocationDots(List<Tuple4<Point<double>, LocationDot, Bubble, DNSServerType>> source, num timestamp) {
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

  /// Start the animation.
  void startAnimation() {
    List<DNSServerType> waypoints = scenarioSelectModel.selectedValues.first.route;
    _routeDrawables.clear();
    _ways.clear();

    bool rootDNSServerSupportsRecursive = false;

    bool isIterative = dnsQueryTypeSelectModel.selectedValues.first is IterativeDNSQueryType;

    _ways = _buildWays(waypoints, isIterative, false); // TODO Add recursive support root check box in gui?

    _nextWaypoint(0);
  }

  List<Tuple3<DNSServerType, DNSServerType, bool>> _buildWays(List<DNSServerType> waypoints, bool isIterative, bool rootDNSSupportsRecursiveLookup) {
    if (isIterative) {
      return _buildIterativeWays(waypoints, DNSServerType.LOCAL);
    } else {
      List<Tuple3<DNSServerType, DNSServerType, bool>> result = List();

      if (rootDNSSupportsRecursiveLookup) {
        // Way forward
        DNSServerType last = DNSServerType.LOCAL;
        for (var type in waypoints) {
          result.add(Tuple3(last, type, true));
          last = type;
        }

        // Way backward
        int length = result.length;
        for (int i = length - 1; i >= 0; i--) {
          var tuple = result[i];
          result.add(Tuple3(tuple.item2, tuple.item1, false));
        }
      } else {
        result.add(Tuple3(DNSServerType.LOCAL, DNSServerType.ROOT, true));
        result.addAll(_buildIterativeWays(waypoints, DNSServerType.ROOT));
        result.add(Tuple3(DNSServerType.ROOT, DNSServerType.LOCAL, false));
      }

      return result;
    }
  }

  List<Tuple3<DNSServerType, DNSServerType, bool>> _buildIterativeWays(List<DNSServerType> waypoints, DNSServerType center) {
    List<Tuple3<DNSServerType, DNSServerType, bool>> result = List();

    for (var type in waypoints) {
      result.add(Tuple3(center, type, true)); // Way forward
      result.add(Tuple3(type, center, false)); // Way backward
    }

    return result;
  }

  void _nextWaypoint(int wayIndex) {
    if (wayIndex < _ways.length) {
      Tuple3<DNSServerType, DNSServerType, bool> way = _ways[wayIndex];

      _currentProgress = MutableProgress();
      _startTimestamp = window.performance.now();
      _routeDrawables.add(WaypointRouteDrawable(_currentProgress, way.item3 ? Colors.SLATE_GREY : Colors.CORAL, way.item1, way.item2));

      _currentProgressListener = _currentProgress.progressChanges.listen((progress) {
        if (progress >= 1.0) {
          _currentProgressListener.cancel();

          _nextWaypoint(wayIndex + 1);
        }
      });
    } else {
      _currentProgress = null;
    }
  }
}
