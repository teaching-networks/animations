import 'package:meta/meta.dart';

class Scenario {
  /// Id of the scenario.
  final int id;

  /// Name of the scenario.
  String name;

  /// Create scenario.
  Scenario({
    @required this.id,
    this.name = "",
  });

  @override
  String toString() {
    return name;
  }
}
