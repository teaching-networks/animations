class Pair<T, E> {
  T first;
  E second;

  Pair({this.first, this.second});

  bool get isFilled => first != null && second != null;
}
