/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular/core.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_list/material_list.dart';
import 'package:angular_components/material_list/material_list_item.dart';
import 'package:angular_components/material_select/material_select_item.dart';
import 'package:angular_components/material_spinner/material_spinner.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/view/management/content/management_component_content.dart';

/// Factory for entities.
typedef T EntityFactory<T>();

/// Factory for item labels.
typedef String LabelFactory<T>(T entity);

/// Component to manage remote entities.
@Component(
  selector: "management-component",
  templateUrl: "management.component.html",
  styleUrls: ["management.component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    MaterialListComponent,
    MaterialListItemComponent,
    MaterialSelectItemComponent,
    MaterialIconComponent,
    MaterialSpinnerComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class ManagementComponent<T, C extends ManagementComponentContent> implements OnInit, OnDestroy, AfterViewInit {
  /// Duration to wait before updating the button labels after saving or deleting an entity.
  static const _waitDuration = Duration(seconds: 2);

  /// Change detection reference.
  final ChangeDetectorRef _cd;

  /// Where to get translations from.
  final I18nService _i18n;

  /// Loader to resolve an Angular component.
  final ComponentLoader _componentLoader;

  /// Future loading the entities.
  Future<List<T>> _entityLoadFuture;

  /// Component showing the selected entity.
  ComponentFactory<C> _contentComponentFactory;

  /// Factory for producing fresh entities.
  EntityFactory<T> _entityFactory;

  /// Factory for producing item labels.
  LabelFactory<T> _labelFactory;

  /// Entities to show.
  List<T> _entities;

  /// Currently selected entity.
  T _selectedEntity;

  /// Whether the loading finished with an error.
  bool _hasLoadError = false;

  /// Whether a deletion is currently in progress.
  bool _deleteInProgress = false;

  /// Whether an error happened during deletion.
  bool _deleteError = false;

  /// Whether an entity has been recently deleted.
  bool _recentlyDeleted = false;

  /// Whether a save is currently in progress.
  bool _saveInProgress = false;

  /// Whether an error happened during saving.
  bool _saveError = false;

  /// Whether an entity has been recently saved.
  bool _recentlySaved = false;

  /// Whether creating entities is enabled.
  bool _createEnabled = true;

  /// Whether deleting entities is enabled.
  bool _deleteEnabled = true;

  /// Container where to inject the content component.
  @ViewChild("content", read: ViewContainerRef)
  ViewContainerRef contentContainer;

  /// Instance of the currently loaded content component.
  C _contentComponent;

  /// Listener listening for language changes.
  LanguageLoadedListener _languageLoadedListener;

  Message _errorLabel;
  Message _saveLabel;
  Message _savedLabel;
  Message _deleteLabel;
  Message _deletedLabel;
  Message _emptyNameLabel;

  /// Create new management component.
  ManagementComponent(
    this._cd,
    this._i18n,
    this._componentLoader,
  ) {
    _labelFactory = (entity) => entity != null && entity.toString() != null && entity.toString().length > 0 ? entity.toString() : _emptyNameLabel.toString();
  }

  @override
  void ngOnInit() {
    _languageLoadedListener = (_) {
      _cd.markForCheck();
    };
    _i18n.addLanguageLoadedListener(_languageLoadedListener);

    _initTranslations();
  }

  @override
  void ngOnDestroy() {
    _i18n.removeLanguageLoadedListener(_languageLoadedListener);
  }

  @override
  void ngAfterViewInit() {
    _loadContentComponent();
  }

  /// Initialize the translation messages.
  void _initTranslations() {
    _errorLabel = _i18n.get("management-component.error");
    _saveLabel = _i18n.get("management-component.save");
    _savedLabel = _i18n.get("management-component.saved");
    _deleteLabel = _i18n.get("management-component.delete");
    _deletedLabel = _i18n.get("management-component.deleted");
    _emptyNameLabel = _i18n.get("management-component.empty-name");
  }

  /// What to do when the loading finished.
  void _onLoadFinished(List<T> entities) {
    if (entities == null) {
      _hasLoadError = true;
    } else {
      _hasLoadError = false;
      _entityLoadFuture = null;

      _entities = entities;
    }

    _cd.markForCheck();
  }

  /// Load the content component.
  void _loadContentComponent() {
    if (_contentComponent != null || _contentComponentFactory == null || contentContainer == null) {
      return;
    }

    _contentComponent = _componentLoader.loadNextToLocation(_contentComponentFactory, contentContainer).instance;

    if (_selectedEntity != null) {
      _contentComponent.setEntity(_selectedEntity);
    }
  }

  /// Set the future loading the entities.
  @Input("future")
  void set entityLoadFuture(Future<List<T>> value) {
    _entityLoadFuture = value;

    _entityLoadFuture.then(_onLoadFinished);
  }

  /// Set the content component factory to show a entity.
  @Input("content-component-factory")
  void set contentComponentFactory(ComponentFactory<C> value) {
    _contentComponentFactory = value;
  }

  /// Set the entity factory to produce fresh entities.
  @Input("entity-factory")
  void set entityFactory(EntityFactory<T> value) {
    _entityFactory = value;
  }

  /// Set the label factory producing item labels.
  @Input("label-factory")
  void set labelFactory(LabelFactory<T> value) {
    _labelFactory = value;
  }

  /// Set whether entity creation is enabled.
  @Input("create-enabled")
  set createEnabled(bool value) {
    _createEnabled = value;
  }

  /// Whether entities can be created.
  bool get createEnabled => _createEnabled;

  /// Set whether entity deletion is enabled.
  @Input("delete-enabled")
  set deleteEnabled(bool value) {
    _deleteEnabled = value;
  }

  /// Whether entities can be deleted.
  bool get deleteEnabled => _deleteEnabled;

  /// Get all entities to show.
  List<T> get entities => _entities;

  /// Get the currently selected entity.
  T get selectedEntity => _selectedEntity;

  /// Whether the entities are currently loading.
  bool get isLoading => _entityLoadFuture != null;

  /// Whether loading entities finished with an error.
  bool get hasLoadError => _hasLoadError;

  /// Check if an entity has been selected.
  bool get hasEntitySelected => _selectedEntity != null;

  /// Whether a deletion is in progress.
  bool get isDeleteInProgress => _deleteInProgress;

  /// Whether an error happened during deleting.
  bool get hasDeleteError => _deleteError;

  /// Whether a save is currently in progress.
  bool get isSaveInProgress => _saveInProgress;

  /// Whether an error happened during saving.
  bool get hasSaveError => _saveError;

  /// Whether there has been a save recently.
  bool get hasRecentlySaved => _recentlySaved;

  /// Whether there has been a deletion recently.
  bool get hasRecentlyDeleted => _recentlyDeleted;

  /// Whether the component is allowed to create entities.
  bool get canCreateEntity => _entityFactory != null;

  /// Check whether the passed [entity] is currently selected.
  bool isEntitySelected(T entity) => _selectedEntity == entity;

  /// Select the passed [entity].
  void selectEntity(T entity) {
    _selectedEntity = entity;

    if (_selectedEntity != null) {
      _contentComponent.setEntity(_selectedEntity);
    }
  }

  /// Create a new entity.
  void createEntity() {
    if (!canCreateEntity) {
      return;
    }

    // Produce fresh entity and add it on the bottom of the entity list
    T freshEntity = _entityFactory();

    _entities.add(freshEntity);
    selectEntity(freshEntity);

    _cd.markForCheck();
  }

  /// Delete the passed [entity].
  Future<void> deleteEntity(T entity) async {
    if (_contentComponent == null) {
      return;
    }

    _deleteError = false;
    _deleteInProgress = true;
    _cd.markForCheck();

    bool success = await _contentComponent.onDelete();
    if (success) {
      selectEntity(null);
      entities.remove(entity); // Remove from list

      _recentlyDeleted = true;
      Future.delayed(_waitDuration).then((_) {
        _recentlySaved = false;
        _cd.markForCheck();
      });
    } else {
      _deleteError = true;
    }

    _deleteInProgress = false;
    _cd.markForCheck();
  }

  /// Save the passed [entity].
  Future<void> saveEntity(T entity) async {
    if (_contentComponent == null) {
      return;
    }

    _saveError = false;
    _saveInProgress = true;
    _cd.markForCheck();

    int index = entities.indexOf(entity);

    T saved = await _contentComponent.onSave();
    if (saved != null) {
      entities[index] = saved;
      selectEntity(saved);

      _recentlySaved = true;
      Future.delayed(_waitDuration).then((_) {
        _recentlySaved = false;
        _cd.markForCheck();
      });
    } else {
      _saveError = true;
    }

    _saveInProgress = false;
    _cd.markForCheck();
  }

  /// Get an entity name.
  String getLabel(T entity) => _labelFactory(entity);

  /// Get the label for the delete button.
  String getDeleteButtonLabel() {
    if (_recentlyDeleted) {
      return _deletedLabel.toString();
    } else if (hasDeleteError) {
      return _errorLabel.toString();
    } else if (hasEntitySelected) {
      return "${_deleteLabel.toString()} \"${getLabel(_selectedEntity)}\"";
    } else {
      return _deleteLabel.toString();
    }
  }

  /// Get the label for the save button.
  String getSaveButtonLabel() {
    if (_recentlySaved) {
      return _savedLabel.toString();
    } else if (hasSaveError) {
      return _errorLabel.toString();
    } else if (hasEntitySelected) {
      return "${_saveLabel.toString()} \"${getLabel(_selectedEntity)}\"";
    } else {
      return _saveLabel.toString();
    }
  }
}
