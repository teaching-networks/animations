/// A DNS route describes the path from one DNS server to another.
class DNSRoute {

  final DNSWaypoint from;
  final DNSWaypoint to;

  final bool isAnswer;

  DNSRoute(this.from, this.to, this.isAnswer);

}

enum DNSWaypoint {
  ROOT,
  INTERMEDIATE,
  AUTHORITATIVE,
  LOCAL
}
