/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/animations/dns/dns_system/dns_server_type.dart';
import 'package:hm_animations/src/util/str/message.dart';

class DNSScenario {
  final int id;
  final IdMessage<String> description;
  final List<DNSServerType> route;

  const DNSScenario(this.id, this.description, this.route);
}
