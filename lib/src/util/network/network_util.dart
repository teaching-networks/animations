import 'package:hm_animations/src/util/debug.dart';

class NetworkUtil {
  /// URL of the server.
  static const String _defaultServerURL = "https://www.sam.cs.hm.edu:8443";

  /// URL of the development/debug server.
  static const String _debugServerURL = "http://localhost:4200";

  /// Key of the JSON Web Token in local storage.
  static const String tokenKey = "token";

  /// Get URL with resource relative to base server URL.
  static String getURL(String resource) => "${baseServerURL}/${resource}";

  /// Get the base URL of the server.
  static String get baseServerURL => Debug.isDebugMode ? _debugServerURL : _defaultServerURL;
}
