import 'dart:async';
import 'dart:convert';
import 'package:angular/angular.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/animations/animations.dart';
import 'package:http/http.dart';

/**
 * Service holding all animations.
 */
@Injectable()
class AnimationService {
  Map<String, AnimationDescriptor> _animationDescriptorLookup = new Map<String, AnimationDescriptor>();

  final Client _http;

  AnimationService(this._http) {
    _initAnimationDescriptorLookup();
  }

  void _initAnimationDescriptorLookup() {
    _animationDescriptorLookup.clear();

    for (AnimationDescriptor descriptor in Animations.ANIMATIONS) {
      _animationDescriptorLookup[descriptor.path] = descriptor;
    }
  }

  void login(String username, String password) async {
    var encoded = base64Encode(utf8.encode("${username}:${password}"));

    print(username + " " + password + " => " + encoded);

    try {
      var response = await _http.get("http://localhost:4200/auth", headers: {
        "Authorization": "Basic YmVkZXI6cm9vdA=="
      });

      var jwtToken = response.body;

      print(jwtToken);
    } catch (e) {
      throw Exception("Could not login using the provided credentials");
    }
  }

  Future<Map<String, AnimationDescriptor>> getAnimationDescriptors() async => _animationDescriptorLookup;
}
