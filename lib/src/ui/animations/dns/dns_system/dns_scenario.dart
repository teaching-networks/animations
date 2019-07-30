/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/dns/dns_system/dns_server_type.dart';

class DNSScenario {

  final int id;
  final Message description;
  final List<DNSServerType> route;

  const DNSScenario(this.id, this.description, this.route);

}
