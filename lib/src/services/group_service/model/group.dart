import 'package:hm_animations/src/util/serialize/serializable.dart';
import 'package:meta/meta.dart';

/// Group for animations.
class Group implements Serializable<Group> {
  /// Id of the group.
  int id;

  /// Name of the group.
  String name;

  /// List of animation ids to associate with the group.
  List<int> animationIds;

  /// All animation ids in the correct order.
  List<int> animationIdOrder;

  /// Create group.
  Group({
    this.id,
    @required this.name,
    @required this.animationIds,
    @required this.animationIdOrder,
  });

  /// Create an empty group.
  Group.empty()
      : id = -1,
        name = "",
        animationIds = [];

  @override
  Group fromJson(Map<String, dynamic> json) {
    id = json["id"];
    name = json["name"];

    List<int> animIds = List<int>();
    for (dynamic value in json["animationIds"]) {
      animIds.add(value);
    }
    animationIds = animIds;

    List<int> animIdsOrder = List<int>();
    for (dynamic value in json["animationIdOrder"]) {
      animIdsOrder.add(value);
    }
    animationIdOrder = animIdsOrder;

    return this;
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = Map<String, dynamic>();

    if (id != null) {
      result["id"] = id;
    }

    result["name"] = name;
    result["animationIds"] = animationIds;
    result["animationIdOrder"] = animationIdOrder;

    return result;
  }

  @override
  String toString() {
    return name;
  }
}
