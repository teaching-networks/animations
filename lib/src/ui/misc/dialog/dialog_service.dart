/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:hm_animations/src/ui/misc/dialog/event/dialog_event.dart';
import 'package:hm_animations/src/ui/misc/dialog/impl/prompt/prompt_dialog.dart';
import 'package:hm_animations/src/ui/misc/dialog/impl/prompt/prompt_dialog.template.dart' as $promptDialogTemplate;
import 'package:hm_animations/src/ui/misc/dialog/instance/dialog_instance.dart';

/// Service to easily open dialogs.
@Injectable()
class DialogService implements OnDestroy {
  /// Controller used to emit events.
  final StreamController<DialogEvent> _eventController = StreamController<DialogEvent>.broadcast(sync: false);

  /// Open dialog containing a component produced by the passed [componentFactory].
  /// Returns the ID of the opened dialog.
  DialogInstance<R, T, D> openComponent<R, T, D>(ComponentFactory<T> componentFactory, D data) {
    final instance = DialogInstance<R, T, D>(componentFactory, data);
    _eventController.add(DialogEvent(instance));

    return instance;
  }

  /// Create prompt dialog.
  DialogInstance<String, PromptDialog, String> prompt(String question) {
    return openComponent($promptDialogTemplate.PromptDialogNgFactory, question);
  }

  @override
  void ngOnDestroy() {
    _eventController.close();
  }

  /// Get stream of dialog events.
  Stream<DialogEvent> get events => _eventController.stream;
}
