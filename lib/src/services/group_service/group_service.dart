import 'dart:convert';

import 'package:angular/angular.dart';
import 'package:hm_animations/src/services/group_service/model/group.dart';
import 'package:hm_animations/src/services/network_service/network_service.dart';
import 'package:hm_animations/src/util/network/network_client.dart';
import 'package:hm_animations/src/util/network/network_statuscode.dart';
import 'package:hm_animations/src/util/network/network_util.dart';
import 'package:http/http.dart';

/// Service managing animation groups.
@Injectable()
class GroupService {
  /// Path to the group resource.
  static const String _resourcePath = "api/group";

  /// Service used to make HTTP requests.
  NetworkClient _http;

  /// Create group service.
  GroupService(NetworkService networkService) {
    _http = networkService.client;
  }

  /// Get a group by its [id].
  Future<Group> get(int id) async {
    Response response = await _http.get(NetworkUtil.getURL("$_resourcePath/$id"));

    if (response.statusCode == NetworkStatusCode.OK) {
      return Group.empty().fromJson(json.decode(response.body));
    }

    return null;
  }

  Future<List<Group>> getAll() async {
    Response response = await _http.get(NetworkUtil.getURL(_resourcePath));

    if (response.statusCode == NetworkStatusCode.OK) {
      List<Group> groups = List<Group>();

      for (Map<String, dynamic> jsonGroup in json.decode(response.body)) {
        groups.add(Group.empty().fromJson(jsonGroup));
      }

      return groups;
    }

    return null;
  }

  /// Create a group.
  Future<Group> create(Group group) async {
    Response response = await _http.post(NetworkUtil.getURL(_resourcePath), body: json.encode(group.toJson()));

    if (response.statusCode == NetworkStatusCode.OK) {
      return Group.empty().fromJson(json.decode(response.body));
    }

    return null;
  }

  /// Update a group.
  Future<bool> update(Group group) async {
    Response response = await _http.patch(NetworkUtil.getURL(_resourcePath), body: json.encode(group.toJson()));

    return response.statusCode == NetworkStatusCode.OK;
  }

  /// Delete a group.
  Future<bool> delete(int id) async {
    Response response = await _http.delete(NetworkUtil.getURL("$_resourcePath/$id"));

    return response.statusCode == NetworkStatusCode.OK;
  }
}
