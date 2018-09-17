abstract class Serializable<T> {
  /// Deserialize type T.
  T fromJson(Map<String, dynamic> json);

  /// Serialize from type T.
  Map<String, dynamic> toJson();
}
