import 'package:hm_animations/src/ui/animations/http_delay/http/connection_type/connection_step.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http/connection_type/http_connection_type.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http/http_connection_configuration.dart';

/// A persistent http connection type.
class PersistentHttpConnection implements HttpConnectionType {

  @override
  List<ConnectionStep> generate(HttpConnectionConfiguration configuration) {
    List<ConnectionStep> steps = new List<ConnectionStep>();

    steps.add(ConnectionStep.TCP_CONNECTION_ESTABLISHMENT);
    steps.add(ConnectionStep.HTML_PAGE_REQUEST);

    int realObjectCount = (configuration.objectCount.toDouble() / configuration.parallelConnectionCount).ceil();
    if (!configuration.withPipelining) {
      for (int i = 0; i < realObjectCount; i++) {
        steps.add(ObjectRequestStep(configuration.objectTransmissionDelay));
      }
    } else {
      steps.add(ObjectRequestStep(realObjectCount * configuration.objectTransmissionDelay));
    }

    return steps;
  }

  @override
  String get translationKey => "http-delay-animation.connection-type.persistent";

}