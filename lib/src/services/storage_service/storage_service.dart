import 'dart:html';

import 'package:angular/angular.dart';

/// Service storing data locally.
@Injectable()
class StorageService {

  Storage _storage = window.localStorage;

  /// Check if storage contains the passed [key].
  bool contains(String key) => _storage.containsKey(key);

  /// Get the value associated with the passed [key].
  String get(String key) => _storage[key];

  /// Set the [value] to the passed [key].
  void set(String key, String value) => _storage[key] = value;

  /// Remove the key-value pair associated with the passed [key].
  void remove(String key) => _storage.remove(key);

}