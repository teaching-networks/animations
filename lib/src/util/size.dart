class Size {
  final num width;
  final num height;

  const Size(this.width, this.height);

  const Size.empty()
      : this.width = 0,
        this.height = 0;

  Size operator *(double factor) => Size(width * factor, height * factor);

  @override
  String toString() {
    return "{width: $width, height: $height}";
  }
}
