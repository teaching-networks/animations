/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_ui.dart';
import 'package:hm_animations/src/ui/animations/dns/dns_system/dns_query_type.dart';
import 'package:hm_animations/src/ui/animations/dns/dns_system/dns_scenario.dart';
import 'package:hm_animations/src/ui/animations/dns/dns_system/dns_server_type.dart';
import 'package:hm_animations/src/ui/animations/dns/dns_system/waypoint_route_drawable.dart';
import 'package:hm_animations/src/ui/animations/shared/location_dot/location_dot.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/progress/mutable_progress.dart';
import 'package:hm_animations/src/ui/canvas/shapes/bubble/bubble.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/misc/description/description.component.dart';
import 'package:hm_animations/src/ui/misc/image/image_info.dart';
import 'package:hm_animations/src/ui/misc/image/images.dart';
import 'package:hm_animations/src/util/str/message.dart';
import 'package:tuple/tuple.dart';

@Component(
  selector: "dns-animation",
  styleUrls: ["dns_animation.css"],
  templateUrl: "dns_animation.html",
  directives: [
    coreDirectives,
    MaterialButtonComponent,
    MaterialIconComponent,
    MaterialDropdownSelectComponent,
    MaterialCheckboxComponent,
    MaterialRadioComponent,
    MaterialRadioGroupComponent,
    NgModel,
    CanvasComponent,
    DescriptionComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class DNSAnimation extends CanvasAnimation with AnimationUI implements OnInit, OnDestroy {
  static final int _WRAP_BUBBLE_TEXT_AT = 20;

  final I18nService _i18n;

  /*
  IMAGES TO DRAW IN THE CANVAS.
   */
  final ImageInfo _map = Images.germanyMapImage;
  CanvasImageSource _mapImage;

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
  SelectionModel<DNSQueryType> localDNSQueryTypeSelectModel;
  SelectionModel<DNSQueryType> rootDNSQueryTypeSelectModel;
  static ItemRenderer<DNSQueryType> dnsQueryTypeItemRenderer = (dynamic dnsQueryType) => dnsQueryType.name.toString();

  List<DNSScenario> scenarios;
  DNSScenario selectedScenario;

  List<Tuple2<IdMessage<String>, Color>> _legendItems;

  DNSAnimation(this._i18n) {
    _fillLocationSource();
  }

  void _fillLocationSource() {
    _locationSource.add(Tuple4(_ORIGIN_LOCATION, _originDot, _originBubble, DNSServerType.LOCAL));
    _locationSource.add(Tuple4(_DESTINATION_LOCATION, _destinationDot, _destinationBubble, DNSServerType.DESTINATION));
    _locationSource.add(Tuple4(_ROOT_DNS_SERVER_LOCATION, _rootDNSServerDot, _rootDNSServerBubble, DNSServerType.ROOT));
    _locationSource.add(
        Tuple4(_INTERMEDIATE_DNS_SERVER_LOCATION, _intermediateDNSServerDot, _intermediateDNSServerBubble, DNSServerType.INTERMEDIATE));
    _locationSource.add(
        Tuple4(_AUTHORITATIVE_DNS_SERVER_LOCATION, _authoritativeDNSServerDot, _authoritativeDNSServerBubble, DNSServerType.AUTHORITATIVE));
  }

  @override
  ngOnInit() {
    _initImages();
    _initDNSQueryTypes();
    _initScenarios();
    _initLegend();
  }

  void _initImages() async {
    _mapImage = await _map.load();
  }

  void _initLegend() {
    _legendItems = new List<Tuple2<IdMessage<String>, Color>>();

    _legendItems.add(Tuple2(_i18n.get("dns-animation.legend.query"), Colors.SLATE_GREY));
    _legendItems.add(Tuple2(_i18n.get("dns-animation.legend.response"), Colors.CORAL));
    _legendItems.add(Tuple2(_i18n.get("dns-animation.legend.request"), Colors.TEAL));
  }

  void _initDNSQueryTypes() {
    _dnsQueryTypes = List<DNSQueryType>();

    _dnsQueryTypes.add(IterativeDNSQueryType(_i18n.get("dns-animation.dns-query-type.iterative")));
    _dnsQueryTypes.add(RecursiveDNSQueryType(_i18n.get("dns-animation.dns-query-type.recursive")));

    dnsQueryTypeOptions = SelectionOptions.fromList(_dnsQueryTypes);
    localDNSQueryTypeSelectModel = SelectionModel.single(selected: _dnsQueryTypes.first, keyProvider: (dnsQueryType) => dnsQueryType.id);
    rootDNSQueryTypeSelectModel = SelectionModel.single(selected: _dnsQueryTypes.first, keyProvider: (dnsQueryType) => dnsQueryType.id);
  }

  void _initScenarios() {
    scenarios = List<DNSScenario>();

    scenarios.add(DNSScenario(0, _i18n.get("dns-animation.scenario.root-has-destination-cached"), [DNSServerType.ROOT]));
    scenarios.add(DNSScenario(1, _i18n.get("dns-animation.scenario.root-has-intermediate-cached"),
        [DNSServerType.ROOT, DNSServerType.INTERMEDIATE, DNSServerType.AUTHORITATIVE]));
    scenarios.add(DNSScenario(
        2, _i18n.get("dns-animation.scenario.root-has-authoritative-cached"), [DNSServerType.ROOT, DNSServerType.AUTHORITATIVE]));

    scenarios.add(DNSScenario(3, _i18n.get("dns-animation.scenario.local-has-destination-cached"), []));

    selectedScenario = scenarios[1]; // Pre select second scenario.
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
    double mapWidth = _map.aspectRatio * size.height;
    double mapXOffset = (size.width - mapWidth) / 2;

    if (_mapImage != null) {
      context.drawImageScaled(_mapImage, mapXOffset, 0.0, mapWidth, mapHeight);
    }

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
      if ((routeDrawable.start == DNSServerType.ORIGIN || routeDrawable.end == DNSServerType.ORIGIN) &&
          (routeDrawable.start == DNSServerType.LOCAL || routeDrawable.end == DNSServerType.LOCAL)) {
        // Is loop on same point.
        var point = lookup[DNSServerType.LOCAL].item1;

        var radius = displayUnit * 3;

        context.beginPath();
        setStrokeColor(context, routeDrawable.color);

        var startAngle = pi;
        var endAngle = startAngle + 2 * pi * routeDrawable.progress.progress;
        var clockwise = false;
        if (routeDrawable.start == DNSServerType.LOCAL && routeDrawable.end == DNSServerType.ORIGIN) {
          // Is back direction -> change rotate direction.
          clockwise = true;
          endAngle = startAngle - 2 * pi * routeDrawable.progress.progress;
        }

        context.arc(point.x + radius, point.y, radius, startAngle, endAngle, clockwise);

        context.stroke();
      } else {
        // Normal curve between points.

        var startPoint = lookup[routeDrawable.start].item1;
        var endPoint = lookup[routeDrawable.end].item1;

        if (!routeDrawable.curved) {
          context.setLineDash([]);
        }

        routeDrawable.renderLine(context, startPoint, endPoint);
      }
    }

    _drawLocationDots(source, timestamp);

    _drawLegend();
  }

  void _drawLegend() {
    var legendMargin = displayUnit;
    var itemSize = displayUnit * 2;
    var legendYOffset = size.height - legendMargin * (_legendItems.length + 1) - _legendItems.length * itemSize;

    context.save();

    context.textAlign = "left";
    context.textBaseline = "middle";

    for (var legendItem in _legendItems) {
      setFillColor(context, legendItem.item2);

      context.fillRect(legendMargin, legendYOffset, itemSize, itemSize);
      context.fillText(legendItem.item1.toString(), legendMargin + itemSize + displayUnit / 2, legendYOffset + itemSize / 2);

      legendYOffset += itemSize + legendMargin;
    }

    context.restore();
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

  String get localDNSQueryTypeSelectionLabel => localDNSQueryTypeSelectModel.selectedValues.first.name.toString();

  String get rootDNSQueryTypeSelectionLabel => rootDNSQueryTypeSelectModel.selectedValues.first.name.toString();

  /// Start the animation.
  void startAnimation() {
    List<DNSServerType> waypoints = new List.from(selectedScenario.route);
    _routeDrawables.clear();
    _ways.clear();
    if (_currentProgressListener != null) {
      // If currently running animation
      _currentProgressListener.cancel();
    }

    _ways = new List<Tuple3<DNSServerType, DNSServerType, bool>>();

    _buildWays(DNSServerType.LOCAL, waypoints, _ways);

    // Append way from origin to local name server and back.
    _ways.insert(0, Tuple3(DNSServerType.ORIGIN, DNSServerType.LOCAL, true));
    _ways.add(Tuple3(DNSServerType.LOCAL, DNSServerType.ORIGIN, false));

    _nextWaypoint(0);
  }

  /// Get whether a dns server type is set to iterative (true) or recursive mode (false).
  bool isDNSServerIterative(DNSServerType type) {
    switch (type) {
      case DNSServerType.LOCAL:
        return localDNSQueryTypeSelectModel.selectedValues.first is IterativeDNSQueryType;
      case DNSServerType.ROOT:
        return rootDNSQueryTypeSelectModel.selectedValues.first is IterativeDNSQueryType;
      default:
        return true;
    }
  }

  void _buildWays(DNSServerType current, List<DNSServerType> remainingWaypoints, List<Tuple3<DNSServerType, DNSServerType, bool>> result) {
    if (remainingWaypoints.isEmpty) {
      return;
    }

    bool isIterative = isDNSServerIterative(current);

    if (isIterative) {
      for (DNSServerType waypoint in remainingWaypoints) {
        result.add(Tuple3(current, waypoint, true)); // way forward
        result.add(Tuple3(waypoint, current, false)); // way backward
      }
    } else {
      var next = remainingWaypoints.removeAt(0); // Pop one.

      result.add(Tuple3(current, next, true));
      _buildWays(next, remainingWaypoints, result);
      result.add(Tuple3(next, current, false));
    }
  }

  void _nextWaypoint(int wayIndex) {
    _currentProgress = MutableProgress();
    _startTimestamp = window.performance.now();

    if (wayIndex < _ways.length) {
      Tuple3<DNSServerType, DNSServerType, bool> way = _ways[wayIndex];

      _routeDrawables.add(
          WaypointRouteDrawable(_currentProgress, way.item1, way.item2, color: way.item3 ? Colors.SLATE_GREY : Colors.CORAL, curved: true));

      _currentProgressListener = _currentProgress.progressChanges.listen((progress) {
        if (progress >= 1.0) {
          _currentProgressListener.cancel();

          _nextWaypoint(wayIndex + 1);
        }
      });
    } else {
      // Now animate way to destination.
      _currentProgress = MutableProgress();
      _startTimestamp = window.performance.now();

      _currentProgressListener = _currentProgress.progressChanges.listen((progress) {
        if (progress >= 1.0) {
          _currentProgressListener.cancel();
          _currentProgress = null;
        }
      });

      _routeDrawables
          .add(WaypointRouteDrawable(_currentProgress, DNSServerType.LOCAL, DNSServerType.DESTINATION, color: Colors.TEAL, curved: false));
    }
  }
}
