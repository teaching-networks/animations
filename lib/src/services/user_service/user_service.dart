import 'dart:async';
import 'dart:convert';

import 'package:angular/angular.dart';
import 'package:hm_animations/src/services/network_service/network_service.dart';
import 'package:hm_animations/src/services/user_service/model/user.dart';
import 'package:hm_animations/src/util/network/network_client.dart';
import 'package:hm_animations/src/util/network/network_statuscode.dart';
import 'package:hm_animations/src/util/network/network_util.dart';

@Injectable()
class UserService {
  final NetworkClient _http;

  UserService(NetworkService networkService) : _http = networkService.client;

  Future<User> getUser(int id) async {
    var response = await _http.get(NetworkUtil.getURL("api/user/$id"));

    if (response.statusCode == NetworkStatusCode.OK) {
      return User.empty().fromJson(jsonDecode(response.body));
    }

    return null;
  }

  Future<List<User>> getUsers() async {
    var response = await _http.get(NetworkUtil.getURL("api/user"));

    if (response.statusCode == NetworkStatusCode.OK) {
      return _parseUserList(response.body);
    }

    return [];
  }

  Future<User> createUser(User user) async {
    var response = await _http.post(NetworkUtil.getURL("api/user"), body: jsonEncode(user.toJson()));

    if (response.statusCode == NetworkStatusCode.OK) {
      return User.empty().fromJson(jsonDecode(response.body));
    }

    return null;
  }

  Future<bool> updateUser(User user) async {
    var response = await _http.patch(NetworkUtil.getURL("api/user"), body: jsonEncode(user.toJson()));

    return response.statusCode == NetworkStatusCode.OK;
  }

  Future<bool> deleteUser(int id) async {
    var response = await _http.delete(NetworkUtil.getURL("api/user/$id"));

    return response.statusCode == NetworkStatusCode.OK;
  }

  Future<User> getAuthenticatedUser() async {
    return getUser(-1);
  }

  List<User> _parseUserList(String json) {
    List<dynamic> decoded = jsonDecode(json);

    List<User> result = List<User>();

    if (decoded.isNotEmpty) {
      for (Map<String, dynamic> map in decoded) {
        result.add(User.empty().fromJson(map));
      }
    }

    return result;
  }
}
