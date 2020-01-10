/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_dialog/material_dialog.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/ui/misc/dialog/dialog_component/dialog_component.dart';
import 'package:hm_animations/src/ui/misc/dialog/impl/info/info_dialog_data.dart';

/// Dialog showing a simple info message.
@Component(
  selector: "info-dialog-component",
  templateUrl: "info_dialog.html",
  styleUrls: ["info_dialog.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    MaterialDialogComponent,
    MaterialButtonComponent,
    MaterialIconComponent,
  ],
  pipes: [I18nPipe],
)
class InfoDialog extends DialogComponent<void, InfoDialog, InfoDialogData> {
  /// Close the dialog.
  void close() {
    instance.close();
  }
}
