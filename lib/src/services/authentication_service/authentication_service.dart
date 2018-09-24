import 'dart:async';
import 'dart:convert';

import 'package:angular/angular.dart';
import 'package:hm_animations/src/services/network_service/network_service.dart';
import 'package:hm_animations/src/services/storage_service/storage_service.dart';
import 'package:hm_animations/src/util/network/network_client.dart';
import 'package:hm_animations/src/util/network/network_headers.dart';
import 'package:hm_animations/src/util/network/network_statuscode.dart';
import 'package:hm_animations/src/util/network/network_util.dart';

/// Service handling authentication.
@Injectable()
class AuthenticationService {
  NetworkClient _http;
  final StorageService _storage;

  StreamController<bool> isLoggedInStream = StreamController.broadcast(sync: false);

  AuthenticationService(NetworkService httpService, this._storage) {
    _http = httpService.client;

    _http.authService = this;
  }

  /// Login to server using [username] and [password].
  /// Returns whether it was a success.
  Future<bool> login(String username, String password) async {
    try {
      String token = await _getJSONWebToken(username, password);

      // Store the JSON Web token in local storage.
      _storage.set(NetworkUtil.tokenKey, token);
      isLoggedInStream.add(true);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Logout.
  void logout() async {
    // Just remove the JSON Web Token from storage.
    _storage.remove(NetworkUtil.tokenKey);
    isLoggedInStream.add(false);
  }

  /// Check if user is currently logged in.
  bool get isLoggedIn => _storage.contains(NetworkUtil.tokenKey);

  /// Get stream to listen for login changes.
  Stream<bool> get loggedIn => isLoggedInStream.stream;

  /// Get JSON Web Token using [username] and [password]
  Future<String> _getJSONWebToken(String username, String password) async {
    // Note: Implementation realizes direct basic authentication.
    // Username and password has to be sent via the "Authorization" HTTP header to the server.
    // Username and password need to be encoded in base64 and in the form "username:password".
    // Beforehand the encoded string we need to pass the string "Basic".
    // Example: "Authorization: Basic YYY" (Where YYY ist username:password in base64)

    var encoded = base64Encode(utf8.encode("${username}:${password}"));

    var response = await _http.get(NetworkUtil.getURL("auth"), headers: {NetworkHeaders.AUTHORIZATION: "Basic ${encoded}"});

    if (response.statusCode == NetworkStatusCode.OK) {
      var token = response.body;

      return token;
    } else {
      throw new Exception("Status code was not OK: ${response.statusCode}");
    }
  }
}
