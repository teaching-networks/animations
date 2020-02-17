/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_dialog/material_dialog.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/ui/misc/dialog/dialog_component/dialog_component.dart';

import 'option_dialog_data.dart';

/// Dialog showing a bunch of options the user can choose from.
@Component(
  selector: "option-dialog-component",
  templateUrl: "option_dialog.html",
  styleUrls: ["option_dialog.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    MaterialDialogComponent,
    MaterialButtonComponent,
    MaterialListComponent,
    MaterialListItemComponent,
    MaterialIconComponent,
  ],
  pipes: [I18nPipe],
)
class OptionDialog<T> extends DialogComponent<Option<T>, OptionDialog, OptionDialogData<T>> {
  /// Close the dialog.
  void close() {
    instance.close();
  }

  /// Called when an option is selected.
  void onOptionSelected(Option<T> option) {
    instance.close(option);
  }
}
