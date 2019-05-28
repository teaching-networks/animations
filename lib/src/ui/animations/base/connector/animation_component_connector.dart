import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';

/// Connector to show an animation in the animation base component.
abstract class AnimationComponentConnector {
  /// Get the drawable to render.
  Drawable get drawable;

  /// Get the credits to show.
  String get credits;

  /// Get the animation descriptor of the animation to show.
  AnimationDescriptor<dynamic> get animationDescriptor;
}
