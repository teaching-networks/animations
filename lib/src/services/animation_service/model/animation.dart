/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/util/serialize/serializable.dart';

class Animation implements Serializable<Animation> {
  int id;
  String url;

  Animation(this.id, this.url);

  Animation.empty();

  @override
  Animation fromJson(Map<String, dynamic> json) {
    id = json["id"];
    url = json["url"];

    return this;
  }

  @override
  Map<String, dynamic> toJson() {
    var result = Map<String, dynamic>();

    result["id"] = id;
    result["url"] = url;

    return result;
  }
}
