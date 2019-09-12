/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

class Pair<T, E> {
  T first;
  E second;

  Pair({this.first, this.second});

  bool get isFilled => first != null && second != null;
}
