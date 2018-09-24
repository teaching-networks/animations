import 'package:hm_animations/src/ui/animations/http_delay/http/connection_type/connection_step.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http/http_connection_configuration.dart';

/// Connection type for http.
abstract class HttpConnectionType {

  /// Generate connection steps using the passed [configuration].
  List<ConnectionStep> generate(HttpConnectionConfiguration configuration);

  String get translationKey;

}