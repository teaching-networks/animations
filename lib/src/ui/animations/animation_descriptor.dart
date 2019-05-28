import 'package:angular/angular.dart';
import 'package:meta/meta.dart';

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
   * Base string for all translations of the animation.
   */
  final String baseTranslationKey;

  /**
   * Path to a preview image.
   */
  final String previewImagePath;

  /**
   * Under which path the animation is found later (e. g. /animation/my-animation, where my-animation is the path attribute).
   */
  final String path;

  final int version;

  const AnimationDescriptor({
    @required this.id,
    @required this.componentFactory,
    @required this.baseTranslationKey,
    @required this.previewImagePath,
    @required this.path,
    this.version = 1,
  });
}
