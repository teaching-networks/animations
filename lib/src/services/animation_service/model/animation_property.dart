/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/util/serialize/serializable.dart';

class AnimationProperty implements Serializable<AnimationProperty> {
  int animationId;
  String locale;
  String key;
  String value;

  AnimationProperty({
    this.animationId,
    this.locale,
    this.key,
    this.value,
  });

  AnimationProperty.empty();

  @override
  AnimationProperty fromJson(Map<String, dynamic> json) {
    animationId = json["animationId"];
    locale = json["locale"];
    key = json["key"];
    value = json["value"];

    return this;
  }

  @override
  Map<String, dynamic> toJson() {
    var result = Map<String, dynamic>();

    result["animationId"] = animationId;
    result["locale"] = locale;
    result["key"] = key;
    result["value"] = value;

    return result;
  }
}
