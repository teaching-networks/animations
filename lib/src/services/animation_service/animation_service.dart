import 'dart:async';
import 'package:angular/angular.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/animations/animations.dart';

/**
 * Service holding all animations.
 */
@Injectable()
class AnimationService {
  Map<String, AnimationDescriptor> _animationDescriptorLookup = new Map<String, AnimationDescriptor>();

  AnimationService() {
    _initAnimationDescriptorLookup();
  }

  void _initAnimationDescriptorLookup() {
    _animationDescriptorLookup.clear();

    for (AnimationDescriptor descriptor in Animations.ANIMATIONS) {
      _animationDescriptorLookup[descriptor.path] = descriptor;
    }
  }

  Future<Map<String, AnimationDescriptor>> getAnimationDescriptors() async => _animationDescriptorLookup;
}
