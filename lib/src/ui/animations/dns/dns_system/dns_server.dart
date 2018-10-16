import 'package:hm_animations/src/ui/animations/dns/dns_system/dns_query.dart';
import 'package:hm_animations/src/ui/animations/dns/dns_system/dns_query_mode.dart';
import 'package:hm_animations/src/ui/animations/dns/dns_system/dns_server_type.dart';

typedef void EventConsumer(DNSQuery next);

class DNSServer {
  final DNSServerType type;
  final bool supportsRecursiveLookup;
  DNSServer next;

  DNSServer(this.type, this.supportsRecursiveLookup);

  DNSServer getNext(DNSQueryMode mode) {

  }

  DNSQuery query(DNSQuery query, DNSQueryMode mode) {
    if (query.from == query.to) {
      throw Exception("Endless loop detected");
    }

    return mode == DNSQueryMode.RECURSIVE && this.supportsRecursiveLookup ? _getRecursiveQuery(query) : _getIterativeQuery(query);
  }

  DNSQuery _getIterativeQuery(DNSQuery query) => DNSQuery(query.begin, this, next, true, next == null);

  DNSQuery _getRecursiveQuery(DNSQuery query) {
    var newQuery;
    if (next == null) {
      newQuery = DNSQuery(query.begin, this, query.from, true, true); // Answer the asking server that this server has resolved the domain name.
    } else {
      newQuery = DNSQuery(query.begin, this, next, false, false); // Ask the next server for the domain name.
    }

    return newQuery;
  }
}
