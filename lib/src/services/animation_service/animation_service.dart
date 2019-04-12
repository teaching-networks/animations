import 'dart:async';
import 'dart:convert';

import 'package:angular/angular.dart';
import 'package:hm_animations/src/services/animation_service/model/animation.dart';
import 'package:hm_animations/src/services/authentication_service/authentication_service.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/services/network_service/network_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/animations/animations.dart';
import 'package:hm_animations/src/util/network/network_client.dart';
import 'package:hm_animations/src/util/network/network_statuscode.dart';
import 'package:hm_animations/src/util/network/network_util.dart';

/// Service holding all animations.
@Injectable()
class AnimationService {
  Map<String, AnimationDescriptor<dynamic>> _animationDescriptorLookup = new Map<String, AnimationDescriptor<dynamic>>();

  final AuthenticationService _authService;
  final I18nService _i18n;
  NetworkClient _http;

  AnimationService(
    this._authService,
    this._i18n,
    NetworkService networkService,
  ) {
    _http = networkService.client;

    _initAnimationDescriptorLookup();
  }

  void _initAnimationDescriptorLookup() {
    _animationDescriptorLookup.clear();

    for (AnimationDescriptor descriptor in Animations.ANIMATIONS) {
      _animationDescriptorLookup[descriptor.path] = descriptor;
    }
  }

  Future<Animation> createAnimation(Animation animation) async {
    var response = await _http.post(NetworkUtil.getURL("api/animation"), body: jsonEncode(animation.toJson()));

    if (response.statusCode == NetworkStatusCode.OK) {
      return Animation.empty().fromJson(jsonDecode(response.body));
    }

    return null;
  }

  Future<bool> updateAnimation(Animation animation) async {
    var response = await _http.patch(NetworkUtil.getURL("api/animation"), body: jsonEncode(animation.toJson()));

    return response.statusCode == NetworkStatusCode.OK;
  }

  Future<Animation> getAnimation(int id) async {
    var response = await _http.get(NetworkUtil.getURL("api/animation/$id"));

    if (response.statusCode == NetworkStatusCode.OK) {
      return Animation.empty().fromJson(jsonDecode(response.body));
    }

    return null;
  }

  Future<List<Animation>> getAnimations() async {
    var response = await _http.get(NetworkUtil.getURL("api/animation"));

    if (response.statusCode == NetworkStatusCode.OK) {
      return _parseAnimations(response.body);
    }

    return [];
  }

  Future<Map<String, AnimationDescriptor<dynamic>>> getAnimationDescriptors() async {
    return _animationDescriptorLookup;
  }

  Animation _findAnimationForId(List<Animation> animations, int id) {
    for (Animation animation in animations) {
      if (id == animation.id) {
        return animation;
      }
    }

    return null;
  }

  List<Animation> _parseAnimations(String json) {
    List<dynamic> decoded = jsonDecode(json);

    List<Animation> result = List<Animation>();

    if (decoded.isNotEmpty) {
      for (Map<String, dynamic> map in decoded) {
        result.add(Animation.empty().fromJson(map));
      }
    }

    return result;
  }

  /// Retrieve a property for an animation or null if not found.
  Future<String> getProperty(int animationId, String key) async {
    final response = await _http.get(NetworkUtil.getURL("api/animation/property/${animationId}/${_i18n.getCurrentLocale()}/?key=$key"));

    if (response.statusCode == NetworkStatusCode.OK) {
      Map<String, dynamic> result = json.decode(response.body);

      return result["value"];
    }

    return null;
  }

  /// Set a property for an animation.
  /// Return whether the operation was successful.
  Future<bool> setProperty(int animationId, String key, String value) async {
    final response = await _http.post(NetworkUtil.getURL("api/animation/property/${animationId}/${_i18n.getCurrentLocale()}/?key=$key"), body: value);

    return response.statusCode == NetworkStatusCode.OK;
  }

  /// Retrieve all properties for an animation or null if nothing is found.
  Future<Map<String, String>> getProperties(int animationId) async {
    final response = await _http.get(NetworkUtil.getURL("api/animation/property/${animationId}/${_i18n.getCurrentLocale()}/"));

    if (response.statusCode == NetworkStatusCode.OK) {
      List<dynamic> result = json.decode(response.body);

      if (result == null || result.isEmpty) {
        return null;
      }

      Map<String, String> properties = Map<String, String>();
      for (int i = 0; i < result.length; i++) {
        if (!(result[i] is Map<String, dynamic>)) {
          return null;
        }

        Map<String, dynamic> map = result[i];

        properties[map["key"]] = map["value"];
      }

      return properties;
    }

    return null;
  }
}
