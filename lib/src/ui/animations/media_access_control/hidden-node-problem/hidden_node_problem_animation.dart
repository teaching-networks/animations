import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/hidden-node-problem/node/wireless_node.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:vector_math/vector_math.dart' as v;

/// Animation showing the hidden node problem (RTS/CTS).
@Component(
  selector: "hidden-node-problem-animation",
  styleUrls: [
    "hidden_node_problem_animation.css",
  ],
  templateUrl: "hidden_node_problem_animation.html",
  directives: [
    coreDirectives,
    CanvasComponent,
    MaterialButtonComponent,
    MaterialIconComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class HiddenNodeProblemAnimation extends CanvasAnimation implements OnInit, OnDestroy {
  /// Service to get translations from.
  final I18nService _i18n;

  WirelessNode _accessPoint = WirelessNode(
    nodeName: "X",
    scale: 300000000,
    nodeCircleColor: Colors.PINK_RED,
    rangeCircleColor: Colors.ORANGE,
  );

  List<WirelessNode> _clients = <WirelessNode>[
    WirelessNode(
      nodeName: "A",
      scale: 300000000,
      nodeCircleColor: Colors.LIGHTGREY,
      rangeCircleColor: Colors.ORANGE,
    ),
    WirelessNode(
      nodeName: "B",
      scale: 300000000,
      nodeCircleColor: Colors.LIGHTGREY,
      rangeCircleColor: Colors.ORANGE,
    ),
    WirelessNode(
      nodeName: "C",
      scale: 300000000,
      nodeCircleColor: Colors.LIGHTGREY,
      rangeCircleColor: Colors.ORANGE,
    ),
  ];

  /// Create animation.
  HiddenNodeProblemAnimation(this._i18n);

  @override
  void ngOnInit() {}

  @override
  ngOnDestroy() {
    super.ngOnDestroy();
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    double radius = 200.0;
    _accessPoint.render(context, Rectangle<double>(size.width / 2, size.height / 2, radius, radius), timestamp);

    v.Vector3 vector = v.Vector3(0.0, 1.0, 0.0);
    double radiusOffset = 2 * pi / _clients.length;
    v.Quaternion quaternion = v.Quaternion.axisAngle(v.Vector3(0.0, 0.0, 1.0), radiusOffset);

    for (WirelessNode node in _clients) {
      node.render(context, Rectangle<double>(size.width / 2 - vector.x * radius, size.height / 2 - vector.y * radius, radius, radius), timestamp);

      quaternion.rotate(vector);
    }
  }

  /// Get the height of the canvas.
  int get canvasHeight => 500;

  void test() {
    int index = Random().nextInt(_clients.length);
    _clients[index].emitSignal(Duration(seconds: 3), Color.opacity(Colors.CORAL, 0.3));
  }
}
