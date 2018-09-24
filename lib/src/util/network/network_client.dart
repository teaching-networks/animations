import 'dart:async';
import 'dart:html';

import 'package:hm_animations/src/services/authentication_service/authentication_service.dart';
import 'package:hm_animations/src/util/network/network_headers.dart';
import 'package:hm_animations/src/util/network/network_statuscode.dart';
import 'package:hm_animations/src/util/network/network_util.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart';

/// Custom http client which allows sending http requests with CORS and credentials.
class NetworkClient extends BaseClient {
  BrowserClient _delegate;
  Storage _storage = window.localStorage;
  AuthenticationService _authService;

  NetworkClient() {
    _delegate = BrowserClient();

    // Configure BrowserClient to use "withCredentials" (for sending CORS requests with Authorization header).
    _delegate.withCredentials = true;
  }

  void set authService(AuthenticationService service) => _authService = service;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    if (_storage.containsKey(NetworkUtil.tokenKey)) {
      var token = _storage[NetworkUtil.tokenKey];

      // Set JSON web token in the Authorization header.
      request.headers[NetworkHeaders.AUTHORIZATION] = "$token";
    }

    StreamedResponse response = await _delegate.send(request);

    if (response.statusCode == NetworkStatusCode.UNAUTHORIZED) {
      // If Unauthorized
      if (_authService != null) {
        _authService.logout();
      }
    }

    return response;
  }
}
