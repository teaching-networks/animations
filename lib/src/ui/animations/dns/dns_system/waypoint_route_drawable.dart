import 'package:hm_animations/src/ui/animations/dns/dns_system/dns_server_type.dart';
import 'package:hm_animations/src/ui/animations/shared/route/route_drawable.dart';
import 'package:hm_animations/src/ui/canvas/progress/progress.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';

class WaypointRouteDrawable extends RouteDrawable {
  final DNSServerType start;
  final DNSServerType end;

  WaypointRouteDrawable(Progress progress, this.start, this.end, {Color color, bool curved}) : super(progress, color: color, curved: curved);
}
