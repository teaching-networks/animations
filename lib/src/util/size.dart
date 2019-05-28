class Size {
  num width;
  num height;

  Size(this.width, this.height);

  Size operator *(double factor) => Size(width * factor, height * factor);

  @override
  String toString() {
    return "{width: $width, height: $height}";
  }
}
