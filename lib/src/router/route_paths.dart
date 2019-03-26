import 'package:angular_router/angular_router.dart';

const String idParam = "id";

final overview = new RoutePath(path: "overview");
final animation = new RoutePath(path: "animation/:$idParam");
final detail = new RoutePath(path: "detail/:$idParam");
final user = new RoutePath(path: "user");
final groupManagement = new RoutePath(path: "manage-groups");
final notFound = new RoutePath(path: ".+");

String getId(Map<String, String> parameters) {
  return parameters[idParam];
}
