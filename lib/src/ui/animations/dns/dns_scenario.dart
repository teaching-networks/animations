import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/dns/dns_route.dart';

class DNSScenario {
  final DNSScenarioType type;
  final Message description;

  DNSScenario(this.type, this.description);

  List<DNSRoute> getRoute(bool isIterative) {
    var route = List<DNSRoute>();

    var currentWaypoint = DNSWaypoint.LOCAL;

    bool hasDestination = false;
    while (!hasDestination) {
      DNSRoute next = _getNextRoutePart(currentWaypoint, isIterative);

      if (next == null) {
        break;
      }

      currentWaypoint = next.to;

      route.add(next);

      if (currentWaypoint == DNSWaypoint.LOCAL) {
        hasDestination = true;
      }
    }

    return route;
  }

  DNSRoute _getNextRoutePart(DNSWaypoint currentWaypoint, bool isIterative) {
    DNSWaypoint nextWaypoint = null;
    bool isAnswer = false;

    switch (type) {
      case DNSScenarioType.ROOT_HAS_DESTINATION_CACHED:
        // Route from local name server to root server and back.
        if (currentWaypoint == DNSWaypoint.LOCAL) {
          nextWaypoint = DNSWaypoint.ROOT;
        } else {
          nextWaypoint = DNSWaypoint.LOCAL;
          isAnswer = true;
        }
        break;
      case DNSScenarioType.ROOT_HAS_INTERMEDIATE_CACHED:
        switch (currentWaypoint) {
          case DNSWaypoint.LOCAL:
            nextWaypoint = DNSWaypoint.ROOT;
            break;
        }
        break;
      case DNSScenarioType.ROOT_HAS_AUTHORITATIVE_CACHED:
        break;
      case DNSScenarioType.LOCAL_HAS_DESTINATION_CACHED:
        // Already finished, since the local name server already has the destination IP.
        return null;
      default:
        throw Exception("Scenario type unknown.");
    }

    return DNSRoute(currentWaypoint, nextWaypoint, isAnswer);
  }
}

enum DNSScenarioType { ROOT_HAS_DESTINATION_CACHED, ROOT_HAS_INTERMEDIATE_CACHED, ROOT_HAS_AUTHORITATIVE_CACHED, LOCAL_HAS_DESTINATION_CACHED }
