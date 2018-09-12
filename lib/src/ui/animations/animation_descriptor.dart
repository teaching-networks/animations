import 'package:angular/angular.dart';

class AnimationDescriptor<T> {
  /**
   * Id of the animation.
   */
  final int id;
  /**
   * Type of the animation (e. g. the Animation components class).
   */
  final ComponentFactory<T> componentFactory;

  /**
   * Name of the animation.
   */
  final String name;

  /**
   * Path to a preview image.
   */
  final String previewImagePath;

  /**
   * Under which path the animation is found later (e. g. /animation/my-animation, where my-animation is the path attribute).
   */
  final String path;

  const AnimationDescriptor(this.id, this.componentFactory, this.name, this.previewImagePath, this.path);
}
