import 'dart:convert';

import 'package:hm_animations/src/util/serialize/serializable.dart';

class Animation implements Serializable<Animation> {

  int id;
  bool visible;

  Animation(this.id, this.visible);
  Animation.empty();

  @override
  Animation fromJson(Map<String, dynamic> json) {
    id = json["id"];
    visible = json["visible"];

    return this;
  }

  @override
  Map<String, dynamic> toJson() {
    var result = Map<String, dynamic>();

    result["id"] = id;
    result["visible"] = visible;

    return result;
  }

}