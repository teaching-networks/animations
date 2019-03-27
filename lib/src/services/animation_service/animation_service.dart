import 'dart:async';
import 'dart:convert';

import 'package:angular/angular.dart';
import 'package:hm_animations/src/services/animation_service/model/animation.dart';
import 'package:hm_animations/src/services/authentication_service/authentication_service.dart';
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
  NetworkClient _http;

  AnimationService(this._authService, NetworkService networkService) {
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
    if (_authService.isLoggedIn) {
      return _animationDescriptorLookup;
    } else {
      List<Animation> animations = await getAnimations();

      var result = Map<String, AnimationDescriptor>();

      for (AnimationDescriptor descriptor in Animations.ANIMATIONS) {
        Animation animation = _findAnimationForId(animations, descriptor.id);

        if (animation == null || animation.visible) {
          result[descriptor.path] = descriptor;
        }
      }

      return result;
    }
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
}
