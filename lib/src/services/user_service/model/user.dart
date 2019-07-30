/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/util/serialize/serializable.dart';

class User implements Serializable<User> {
  int id;
  String name;
  String password;

  User(this.id, this.name, this.password);

  User.empty();

  @override
  User fromJson(Map<String, dynamic> json) {
    id = json["id"];
    name = json["name"];

    if (json.containsKey("password")) {
      password = json["password"];
    }

    return this;
  }

  @override
  Map<String, dynamic> toJson() {
    var result = Map<String, dynamic>();

    result["id"] = id;
    result["name"] = name;

    if (password != null) {
      result["password"] = password;
    }

    return result;
  }

  @override
  String toString() {
    return name;
  }
}
