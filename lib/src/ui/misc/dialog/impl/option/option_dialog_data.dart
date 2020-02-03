import 'package:hm_animations/src/util/str/message.dart';
import 'package:meta/meta.dart';

/// Input data for the option dialog.
class OptionDialogData<T> {
  /// Title of the dialog.
  final Message title;

  /// Message of the dialog.
  final Message message;

  /// Options available.
  final List<Option<T>> options;

  /// Create dialog data.
  OptionDialogData({
    @required this.title,
    @required this.message,
    @required this.options,
  });
}

/// Option of the dialog.
abstract class Option<T> {
  /// Option value.
  T get value;

  @override
  String toString();
}

class LabeledOption<T> implements Option<T> {
  /// Value of the option.
  final String label;

  /// Value of the option.
  final T value;

  /// Create option.
  LabeledOption(this.label, this.value);

  @override
  String toString() {
    return label;
  }
}
