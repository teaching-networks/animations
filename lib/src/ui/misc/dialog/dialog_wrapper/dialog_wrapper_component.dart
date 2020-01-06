/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:hm_animations/src/ui/misc/dialog/dialog_component/dialog_component.dart';
import 'package:hm_animations/src/ui/misc/dialog/dialog_service.dart';
import 'package:hm_animations/src/ui/misc/dialog/event/dialog_event.dart';
import 'package:hm_animations/src/ui/misc/dialog/instance/dialog_instance.dart';

/// Component able to display one or multiple dialogs.
@Component(
  selector: "dialog-wrapper-component",
  templateUrl: "dialog_wrapper_component.html",
  styleUrls: ["dialog_wrapper_component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
  ],
)
class DialogWrapperComponent implements OnInit, OnDestroy {
  /// Change detector reference.
  final ChangeDetectorRef _cd;

  /// Service globally used to display dialogs with.
  final DialogService _service;

  /// Loader to resolve the correct Angular component.
  final ComponentLoader _componentLoader;

  /// List of dialog instances to show.
  final List<DialogInstance> instances = List<DialogInstance>();

  /// Container where the dialog instances are created in.
  @ViewChild('container', read: ViewContainerRef)
  ViewContainerRef container;

  /// Subscription to dialog service events.
  StreamSubscription<DialogEvent> _eventSub;

  /// Create component.
  DialogWrapperComponent(this._cd, this._service, this._componentLoader);

  @override
  void ngOnDestroy() {
    _eventSub.cancel();
  }

  @override
  void ngOnInit() {
    _eventSub = _service.events.listen((event) {
      _displayDialog(event.instance);
    });
  }

  /// Display a dialog instance.
  void _displayDialog(DialogInstance instance) {
    instances.add(instance);
    _cd.markForCheck(); // Update container list

    ComponentRef<DialogComponent> componentRef = _componentLoader.loadNextToLocation(instance.componentFactory, container);
    componentRef.instance.setInstance(instance);

    instance.result().then((_) {
      _removeDialog(instance, componentRef.hostView);
    });
  }

  /// Remove dialog instance.
  void _removeDialog(DialogInstance instance, ViewRef viewRef) {
    container.remove(container.indexOf(viewRef));
    instances.remove(instance);
    this._cd.markForCheck();
  }

  /// Whether dialogs are shown currently.
  bool isDialogShown() {
    return instances.isNotEmpty;
  }

  String getModalVisibility() {
    return isDialogShown() ? "block": "none";
  }
}
