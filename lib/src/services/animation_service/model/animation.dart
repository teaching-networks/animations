import 'dart:convert';

class Animation {

  int id;
  bool visible;

  Animation(this.id, this.visible);

  Animation.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    visible = json["visible"];
  }

  static String toJson(Animation animation) {
    var result = Map<String, dynamic>();

    result["id"] = animation.id;
    result["visible"] = animation.visible;

    return jsonEncode(result);
  }

}