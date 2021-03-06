/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:angular_router/angular_router.dart';

const String idParam = "id";

final groups = new RoutePath(path: "groups");
final group = new RoutePath(path: "group/:$idParam");
final animation = new RoutePath(path: "animation/:$idParam");
final detail = new RoutePath(path: "detail/:$idParam");
final userManagement = new RoutePath(path: "management/user");
final groupManagement = new RoutePath(path: "management/group");
final animationManagement = new RoutePath(path: "management/animation");
final settingsManagement = new RoutePath(path: "management/settings");
final notFound = new RoutePath(path: ".+");

String getId(Map<String, String> parameters) {
  return parameters[idParam];
}
