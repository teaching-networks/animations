typedef String LabelSupplier<T>(T object);

/// Option class as model for the material radio component.
class Option<T> {
  final String label;
  LabelSupplier<T> labelSupplier;

  bool selected;
  bool disabled;

  T object;

  Option({this.label = "Label", this.labelSupplier = null, this.selected = false, this.disabled = false, this.object});

  @override
  String toString() {
    if (labelSupplier != null && object != null) {
      return labelSupplier(object);
    } else {
      return label;
    }
  }
}
