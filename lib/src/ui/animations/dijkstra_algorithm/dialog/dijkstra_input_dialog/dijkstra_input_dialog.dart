/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/focus/focus.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_dialog/material_dialog.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_input/material_input.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node_connection.dart';
import 'package:hm_animations/src/ui/misc/dialog/dialog_component/dialog_component.dart';
import 'package:hm_animations/src/ui/misc/dialog/instance/dialog_instance.dart';
import 'package:hm_animations/src/ui/misc/directives/auto_select_directive.dart';

/// Dijkstra input dialog to edit arrows.
/// Its result is whether the currently edited connection should be removed.
@Component(
  selector: "dijkstra-input-dialog-component",
  templateUrl: "dijkstra_input_dialog.html",
  styleUrls: ["dijkstra_input_dialog.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    materialInputDirectives,
    MaterialButtonComponent,
    MaterialIconComponent,
    MaterialDialogComponent,
    AutoFocusDirective,
    AutoSelectDirective,
    formDirectives,
  ],
  pipes: [I18nPipe],
)
class DijkstraInputDialog extends DialogComponent<bool, DijkstraInputDialog, DijkstraNodeConnection> {
  /// The current weight shown in the dialog input.
  String currentWeight = "";

  /// Whether to show the delete security question.
  bool showDeleteConnectionSecurityQuestion = false;

  /// Text field where the user can set a new weight for a connection between nodes.
  @ViewChild("newWeightTextField", read: HtmlElement)
  HtmlElement newWeightTextField;

  @override
  void setInstance(DialogInstance<dynamic, DijkstraInputDialog, DijkstraNodeConnection> value) {
    super.setInstance(value);

    currentWeight = instance.data.weight.toString();
  }

  /// Remove the currently editing arrow.
  void removeArrow() {
    instance.close(true);
  }

  /// Cancel the dialog.
  void cancel() {
    instance.close(false);
  }

  /// Finish the dialog.
  void ok() {
    int value = int.tryParse(currentWeight) ?? 0;

    if (instance.data != null) {
      instance.data.weight = value;
    }

    instance.close(false);
  }
}
