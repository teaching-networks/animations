import 'dart:html';

import 'package:hm_animations/src/util/debug.dart';

class NetworkUtil {
  /// URL of the server.
  static const String _defaultServerURL = "https://www.sam.cs.hm.edu:8443";

  /// URL of the development/debug server.
  static const String _debugServerURL = "http://localhost:4200";

  /// Key of the JSON Web Token in local storage.
  static const String tokenKey = "token";

  /// Base URL will be cached here for multiple requests.
  static Uri _baseUriCache;

  /// Get the base Uri of the webpage.
  /// The base URL is defined by the origin (for example: https://myname:1234)
  /// and the base href defined in the index.html (for example: <base href="/">).
  static Uri get baseUri {
    if (_baseUriCache != null) {
      return _baseUriCache;
    }

    String origin = Uri.base.origin;

    List<Node> baseNodes = document.getElementsByTagName("base");
    assert(baseNodes.length >= 1);

    Node baseNode = baseNodes.first;
    assert(baseNode is Element);

    Element element = baseNode as Element;
    String href = element.attributes["href"];
    assert(href != null);

    _baseUriCache = Uri.parse(origin + href);
    return _baseUriCache;
  }

  /// Get URL with resource relative to base server URL.
  static String getURL(String resource) => "${baseServerURL}/${resource}";

  /// Get the base URL of the server.
  static String get baseServerURL => Debug.isDebugMode ? _debugServerURL : _defaultServerURL;
}
