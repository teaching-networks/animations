/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:hm_animations/src/ui/misc/dialog/event/dialog_event.dart';
import 'package:hm_animations/src/ui/misc/dialog/impl/info/info_dialog.dart';
import 'package:hm_animations/src/ui/misc/dialog/impl/info/info_dialog_data.dart';
import 'package:hm_animations/src/ui/misc/dialog/impl/option/option_dialog.dart';
import 'package:hm_animations/src/ui/misc/dialog/impl/option/option_dialog_data.dart';
import 'package:hm_animations/src/ui/misc/dialog/impl/prompt/prompt_dialog.dart';
import 'package:hm_animations/src/ui/misc/dialog/impl/prompt/prompt_dialog.template.dart' as $promptDialogTemplate;
import 'package:hm_animations/src/ui/misc/dialog/impl/base_dialog/base_dialog.template.dart' as $baseDialogTemplate;
import 'package:hm_animations/src/ui/misc/dialog/impl/info/info_dialog.template.dart' as $infoDialogTemplate;
import 'package:hm_animations/src/ui/misc/dialog/impl/option/option_dialog.template.dart' as $optionDialogTemplate;
import 'package:hm_animations/src/ui/misc/dialog/instance/dialog_instance.dart';

/// Service to easily open dialogs.
@Injectable()
class DialogService implements OnDestroy {
  /// Controller used to emit events.
  final StreamController<DialogEvent> _eventController = StreamController<DialogEvent>.broadcast(sync: false);

  /// Open dialog containing a component produced by the passed [componentFactory].
  /// Returns the ID of the opened dialog.
  DialogInstance<R, T, D> openComponent<R, T, D>(
    ComponentFactory<T> componentFactory,
    D data, {
    bool useDefaultLayoutComponentFactory = true,
    ComponentFactory dialogLayoutComponentFactory, // Component used to position the dialog component (nullable)
  }) {
    final instance = DialogInstance<R, T, D>(componentFactory, data);
    _eventController.add(DialogEvent(instance, useDefaultLayoutComponentFactory ? $baseDialogTemplate.BaseDialogNgFactory : dialogLayoutComponentFactory));

    return instance;
  }

  /// Open prompt dialog.
  DialogInstance<String, PromptDialog, String> prompt(String question) {
    return openComponent($promptDialogTemplate.PromptDialogNgFactory, question);
  }

  /// Open info dialog.
  DialogInstance<void, InfoDialog, InfoDialogData> info(InfoDialogData data) {
    return openComponent($infoDialogTemplate.InfoDialogNgFactory, data);
  }

  /// Open option dialog providing several options the user can choose from.
  DialogInstance<Option<T>, OptionDialog, OptionDialogData<T>> option<T>(OptionDialogData<T> data) {
    return openComponent($optionDialogTemplate.OptionDialogNgFactory, data);
  }

  @override
  void ngOnDestroy() {
    _eventController.close();
  }

  /// Get stream of dialog events.
  Stream<DialogEvent> get events => _eventController.stream;
}
