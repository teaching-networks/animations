import 'dart:html';

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
    directives: [coreDirectives, MaterialButtonComponent, MaterialIconComponent, CanvasComponent],
    pipes: [I18nPipe])
class DNSAnimation extends CanvasAnimation implements OnDestroy {
  static final int _WRAP_BUBBLE_TEXT_AT = 20;

  /// Aspect ratio of the world map SVG -> width / height.
  static final double WORLD_MAP_ASPECT_RATIO = 1700.0 / 1000.0;

  static final Point<double> _ORIGIN_LOCATION = Point(0.487, 0.25);
  static final Point<double> _DESTINATION_LOCATION = Point(0.25, 0.3);
  static final Point<double> _ROOT_DNS_SERVER_LOCATION = Point(0.45, 0.2);

  final I18nService _i18n;

  /*
  IMAGES TO DRAW IN THE CANVAS.
   */
  final ImageElement _worldMap = new ImageElement(src: "img/animation/world_map.svg");

  LocationDot _originDot = LocationDot(color: Colors.SPACE_BLUE);
  Bubble _originBubble = Bubble("Requesting Host (Origin) / Local Name Server", _WRAP_BUBBLE_TEXT_AT);

  LocationDot _destinationDot = LocationDot(color: Colors.TEAL);
  Bubble _destinationBubble = Bubble("Destination Host (example.com)", _WRAP_BUBBLE_TEXT_AT);

  LocationDot _rootDNSServerDot = LocationDot(color: Colors.LIME);
  Bubble _rootDNSServerBubble = Bubble("Root DNS Server (K)", _WRAP_BUBBLE_TEXT_AT);

  MutableProgress _testProgress = MutableProgress();
  Duration _testDuration = Duration(seconds: 2);
  RouteDrawable _test;
  num _startTimestamp;

  List<LocationDot> _locationDots;
  List<Point<double>> _locations;
  List<Bubble> _bubbles;

  DNSAnimation(this._i18n) {
    _test = RouteDrawable(_testProgress);

    _locations = [
      _ORIGIN_LOCATION,
      _DESTINATION_LOCATION,
      _ROOT_DNS_SERVER_LOCATION
    ];

    _locationDots = [
      _originDot,
      _destinationDot,
      _rootDNSServerDot
    ];

    _bubbles = [
      _originBubble,
      _destinationBubble,
      _rootDNSServerBubble
    ];
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

    _drawBackground();

    var realLocations = List<Point<double>>();
    for (var location in _locations) {
      realLocations.add(_calculatePoint(location));
    }

    // TODO Animated line from point to point (Maybe a curve, like planes would fly)
    setStrokeColor(context, Colors.SLATE_GREY);
    context.setLineDash([displayUnit, displayUnit / 2]);
    context.lineWidth = displayUnit / 3;
    _test.renderLine(context, realLocations[0], realLocations[1]);

    _drawLocationDots(realLocations, _locationDots, _bubbles, timestamp);
  }

  void _drawBackground() {
    context.drawImageScaled(_worldMap, 0.0, 0.0, size.width, size.height);
  }

  void _drawLocationDots(List<Point<double>> locations, List<LocationDot> dots, List<Bubble> bubbles, num timestamp) {
    double dotSize = displayUnit;

    // Draw dots
    for (int i = 0; i < dots.length; i++) {
      var location = locations[i];
      var dot = dots[i];

      dot.render(context, Rectangle<double>(location.x, location.y, dotSize, dotSize), timestamp);
    }

    // Draw bubbles
    for (int i = 0; i < dots.length; i++) {
      var location = locations[i];
      var bubble = bubbles[i];

      bubble.render(context, Rectangle<double>(location.x, location.y - dotSize * 1.5, dotSize, dotSize));
    }
  }

  Point<double> _calculatePoint(Point<double> relativePoint) => Point(relativePoint.x * size.width, relativePoint.y * size.height);

}
