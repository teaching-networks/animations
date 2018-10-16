import 'package:hm_animations/src/ui/animations/dns/dns_system/dns_server.dart';

class DNSQuery {

  final DNSServer begin;
  final DNSServer from;
  final DNSServer to;

  /// Whether the query is meant as answer to the querying server.
  final bool isAnswer;

  /// Whether the query could be resolved.
  final bool isResolved;

  DNSQuery(this.begin, this.from, this.to, this.isAnswer, this.isResolved);

}