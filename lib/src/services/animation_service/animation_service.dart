/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';
import 'dart:convert';

import 'package:angular/angular.dart';
import 'package:hm_animations/src/services/animation_service/model/animation.dart';
import 'package:hm_animations/src/services/animation_service/model/animation_property.dart';
import 'package:hm_animations/src/services/network_service/network_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/animations/animations.dart';
import 'package:hm_animations/src/util/network/network_client.dart';
import 'package:hm_animations/src/util/network/network_statuscode.dart';
import 'package:hm_animations/src/util/network/network_util.dart';

/// Service holding all animations.
@Injectable()
class AnimationService {
  Map<int, AnimationDescriptor<dynamic>> _animationDescriptorLookup = new Map<int, AnimationDescriptor<dynamic>>();

  NetworkClient _http;

  AnimationService(
    NetworkService networkService,
  ) {
    _http = networkService.client;

    _initAnimationDescriptorLookup();
  }

  void _initAnimationDescriptorLookup() {
    _animationDescriptorLookup.clear();

    for (AnimationDescriptor descriptor in Animations.ANIMATIONS) {
      _animationDescriptorLookup[descriptor.id] = descriptor;
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

  Map<int, AnimationDescriptor<dynamic>> getAnimationDescriptors() {
    return _animationDescriptorLookup;
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
  Future<AnimationProperty> getProperty({
    String locale,
    int animationId,
    String key,
  }) async {
    final result = await getProperties(
      locale: locale,
      animationId: animationId,
      key: key,
    );

    if (result != null && result.length == 1) {
      return result.first;
    }

    return null;
  }

  /// Set a property for an animation.
  /// Return whether the operation was successful.
  Future<bool> setProperty(String locale, int animationId, String key, String value) async {
    final response = await _http.post(
        NetworkUtil.getURLWithParams("api/animation/property", {
          "locale": locale,
          "animationid": animationId,
          "key": key,
        }),
        body: value);

    return response.statusCode == NetworkStatusCode.OK;
  }

  /// Retrieve all properties for an animation or null if nothing is found.
  Future<List<AnimationProperty>> getProperties({
    String locale,
    int animationId,
    String key,
  }) async {
    final response = await _http.get(NetworkUtil.getURLWithParams("api/animation/property", {
      "locale": locale,
      "animationid": animationId,
      "key": key,
    }));

    if (response.statusCode == NetworkStatusCode.OK) {
      dynamic result = json.decode(response.body);

      if (result == null) {
        return null;
      }

      List<AnimationProperty> properties = List<AnimationProperty>();

      if (result is Map<String, dynamic>) {
        properties.add(AnimationProperty.empty().fromJson(result));
      } else if (result is List<dynamic>) {
        for (int i = 0; i < result.length; i++) {
          if (!(result[i] is Map<String, dynamic>)) {
            return null;
          }

          Map<String, dynamic> map = result[i];

          properties.add(AnimationProperty.empty().fromJson(map));
        }
      }

      return properties;
    }

    return null;
  }
}
