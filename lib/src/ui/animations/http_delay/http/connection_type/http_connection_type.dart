/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/animations/http_delay/http/connection_type/connection_step.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http/http_connection_configuration.dart';

/// Connection type for http.
abstract class HttpConnectionType {

  /// Generate connection steps using the passed [configuration].
  List<ConnectionStep> generate(HttpConnectionConfiguration configuration);

  String get translationKey;

}
