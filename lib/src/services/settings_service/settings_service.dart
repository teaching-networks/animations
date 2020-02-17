/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:convert';

import 'package:angular/angular.dart';
import 'package:hm_animations/src/services/network_service/network_service.dart';
import 'package:hm_animations/src/services/settings_service/model/setting.dart';
import 'package:hm_animations/src/util/network/network_client.dart';
import 'package:hm_animations/src/util/network/network_statuscode.dart';
import 'package:hm_animations/src/util/network/network_util.dart';

/// Service managing app settings.
@Injectable()
class SettingsService {
  final NetworkClient _http;

  SettingsService(NetworkService networkService) : _http = networkService.client;

  Future<Setting<T>> read<T>(String key) async {
    var response = await _http.get(NetworkUtil.getURL("api/settings/$key"));

    if (response.statusCode == NetworkStatusCode.OK) {
      final map = jsonDecode(response.body);
      return _parseSetting(map);
    }

    return null;
  }

  Future<List<Setting<dynamic>>> readAll() async {
    var response = await _http.get(NetworkUtil.getURL("api/settings"));

    if (response.statusCode == NetworkStatusCode.OK) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((m) => _parseSetting(m)).toList();
    }

    return [];
  }

  Future<Setting<T>> create<T>(Setting<T> s) async {
    var response = await _http.post(NetworkUtil.getURL("api/settings"), body: jsonEncode(_serializeSetting(s)));

    if (response.statusCode == NetworkStatusCode.OK) {
      final map = jsonDecode(response.body);
      return _parseSetting(map);
    }

    return null;
  }

  Setting<dynamic> _parseSetting(Map<String, dynamic> m) {
    String type = m["type"];

    switch (type) {
      case "string":
        return Setting<String>.from(m["key"], m["value"]);
      case "bool":
        return Setting<bool>.from(m["key"], (m["value"] as String).toLowerCase() == 'true');
      default:
        throw Exception("Setting type unknown");
    }
  }

  Map<String, dynamic> _serializeSetting(Setting<dynamic> s) {
    String type = getType(s.value);

    return {
      "key": s.key,
      "type": type,
      "value": s.value,
    };
  }

  String getType(dynamic value) {
    if (value is bool) {
      return "bool";
    } else if (value is String) {
      return "string";
    } else {
      throw Exception("Setting type unknown");
    }
  }

  Future<bool> update(Setting<dynamic> s) async {
    var response = await _http.patch(NetworkUtil.getURL("api/settings"), body: jsonEncode(_serializeSetting(s)));

    return response.statusCode == NetworkStatusCode.OK;
  }

  Future<bool> delete(String key) async {
    var response = await _http.delete(NetworkUtil.getURL("api/settings/$key"));

    return response.statusCode == NetworkStatusCode.OK;
  }
}
