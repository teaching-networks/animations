class AnimationDescriptor {

  /**
   * Type of the animation (e. g. the Animation components class).
   */
  final Type type;

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

  const AnimationDescriptor(this.type, this.name, this.previewImagePath, this.path);

}