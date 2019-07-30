/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:angular_components/model/selection/select.dart';
import 'package:angular_components/model/selection/string_selection_options.dart';

class SelectionOptions<T> extends StringSelectionOptions<T> implements Selectable {
  SelectionOptions(List<T> options) : super(options, toFilterableString: (option) => option.toString());

  @override
  SelectableOption getSelectable(item) => SelectableOption.Selectable;
}
