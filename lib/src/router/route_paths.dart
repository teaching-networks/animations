import 'package:angular_router/angular_router.dart';

const String idParam = "id";

final groups = new RoutePath(path: "groups");
final group = new RoutePath(path: "group/:$idParam");
final animation = new RoutePath(path: "animation/:$idParam");
final detail = new RoutePath(path: "detail/:$idParam");
final userManagement = new RoutePath(path: "manage-users");
final groupManagement = new RoutePath(path: "manage-groups");
final notFound = new RoutePath(path: ".+");

String getId(Map<String, String> parameters) {
  return parameters[idParam];
}
