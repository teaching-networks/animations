/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:angular/angular.dart';
import 'package:angular_components/focus/focus.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_dialog/material_dialog.dart';
import 'package:angular_components/material_input/material_input.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/ui/misc/dialog/dialog_component/dialog_component.dart';

/// Dialog featuring a simple prompt.
@Component(
  selector: "prompt-dialog-component",
  templateUrl: "prompt_dialog.html",
  styleUrls: ["prompt_dialog.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    MaterialButtonComponent,
    MaterialDialogComponent,
    AutoFocusDirective,
    materialInputDirectives,
    formDirectives,
  ],
  pipes: [I18nPipe],
)
class PromptDialog extends DialogComponent<String, String> {
  /// Typed in answer.
  String answer = "";

  /// Cancel the prompt.
  void cancel() {
    instance.close();
  }

  /// Close the prompt.
  void close() {
    instance.close(answer);
  }

  /// Get the question to ask in the prompt dialog.
  String get question => instance.data;
}
