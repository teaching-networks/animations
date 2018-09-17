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
    var response = await _http.get(NetworkUtil.getURL("api/user"));

    if (response.statusCode == NetworkStatusCode.OK) {
      return User.empty().fromJson(jsonDecode(response.body));
    }

    return null;
  }

  Future<List<User>> getUsers() async {

  }

}