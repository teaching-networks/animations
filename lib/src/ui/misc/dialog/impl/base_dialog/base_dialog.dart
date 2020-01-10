/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:angular/angular.dart';
import 'package:hm_animations/src/ui/misc/dialog/dialog_component/dialog_component.dart';
import 'package:hm_animations/src/ui/misc/dialog/instance/dialog_instance.dart';

/// Base component for each dialog.
/// It handles positioning the dialog properly.
@Component(
  selector: "base-dialog-component",
  styleUrls: ["base_dialog.css"],
  templateUrl: "base_dialog.html",
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class BaseDialog extends DialogComponent {
  /// Change detector reference.
  final ChangeDetectorRef _cd;

  /// Loader to resolve the correct Angular component.
  final ComponentLoader _componentLoader;

  /// Container to fill with the actual dialog.
  @ViewChild("base", read: ViewContainerRef)
  ViewContainerRef baseContainer;

  /// Create base dialog.
  BaseDialog(this._cd, this._componentLoader);

  @override
  void setInstance(DialogInstance value) {
    super.setInstance(value);

    _loadDialogComponent();
  }

  /// Load the actual dialog component to show in the base container.
  void _loadDialogComponent() {
    ComponentRef<DialogComponent> componentRef = _componentLoader.loadNextToLocation(instance.componentFactory, baseContainer);
    componentRef.instance.setInstance(instance);
  }
}
