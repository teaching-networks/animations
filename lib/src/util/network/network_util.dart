class NetworkUtil {

  /// URL of the server.
  static const String baseServerURL = "https://www.sam.cs.hm.edu:8443";
  // static const String baseServerURL = "http://localhost:4200";

  /// Key of the JSON Web Token in local storage.
  static const String tokenKey = "token";

  /// Get URL with resource relative to base server URL.
  static String getURL(String resource) => "${baseServerURL}/${resource}";

}
