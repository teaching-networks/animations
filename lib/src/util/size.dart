/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

class Size {
  final num width;
  final num height;

  const Size(this.width, this.height);

  const Size.empty()
      : this.width = 0,
        this.height = 0;

  Size operator *(double factor) => Size(width * factor, height * factor);

  Size operator +(double value) => Size(width + value, height + value);

  @override
  String toString() {
    return "{width: $width, height: $height}";
  }
}
