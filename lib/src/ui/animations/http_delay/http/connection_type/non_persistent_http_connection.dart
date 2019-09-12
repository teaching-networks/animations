/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/animations/http_delay/http/connection_type/connection_step.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http/connection_type/http_connection_type.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http/http_connection_configuration.dart';

/// A non persistent http connection type.
class NonPersistentHttpConnection implements HttpConnectionType {

  @override
  List<ConnectionStep> generate(HttpConnectionConfiguration configuration) {
    List<ConnectionStep> steps = new List<ConnectionStep>();

    steps.add(ConnectionStep.TCP_CONNECTION_ESTABLISHMENT);
    steps.add(ConnectionStep.HTML_PAGE_REQUEST);

    for (int i = 0; i < (configuration.objectCount.toDouble() / configuration.parallelConnectionCount).ceil(); i++) {
      steps.add(ConnectionStep.TCP_CONNECTION_ESTABLISHMENT);
      steps.add(ObjectRequestStep(configuration.objectTransmissionDelay));
    }

    return steps;
  }

  @override
  String get translationKey => "http-delay-animation.connection-type.non-persistent";

}
