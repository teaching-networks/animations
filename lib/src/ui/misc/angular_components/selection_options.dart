import 'package:angular_components/model/selection/select.dart';
import 'package:angular_components/model/selection/string_selection_options.dart';

class SelectionOptions<T> extends StringSelectionOptions<T> implements Selectable {
  SelectionOptions(List<T> options) : super(options, toFilterableString: (option) => option.toString());

  @override
  SelectableOption getSelectable(item) => SelectableOption.Selectable;
}
