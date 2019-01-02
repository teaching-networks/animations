class Size {
  num width;
  num height;

  Size(this.width, this.height);

  @override
  Size operator *(double factor) => Size(width * factor, height * factor);
}
