/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:hm_animations/src/util/size.dart';

/// Service of the carousel component to communicate between items.
@Injectable()
class CarouselService implements OnDestroy {
  /// Controller emitting the selected item.
  StreamController<ItemSelectedChange> _selectedController = StreamController<ItemSelectedChange>.broadcast();

  /// Controller emitting item sizes.
  StreamController<ItemSizeChange> _itemSizeController = StreamController<ItemSizeChange>.broadcast();

  StreamController<SpinChange> _spinController = StreamController<SpinChange>.broadcast();

  /// Inform the service of an items size.
  void informAboutSize(dynamic item, Size size) {
    _itemSizeController.add(ItemSizeChange(item, size));
  }

  /// Get the stream of item sizes.
  Stream<ItemSizeChange> get itemSizeStream => _itemSizeController.stream;

  /// Select the passed item.
  void select(dynamic item, int index) {
    _selectedController.add(ItemSelectedChange(item, index));
  }

  /// Select the next item.
  void selectNext() {
    _spinController.add(SpinChange(true));
  }

  /// Select the previous item.
  void selectPrev() {
    _spinController.add(SpinChange(false));
  }

  /// Get the stream of selected items.
  Stream<ItemSelectedChange> get selectedStream => _selectedController.stream;

  /// Get the stream of spin changes.
  Stream<SpinChange> get spinStream => _spinController.stream;

  @override
  void ngOnDestroy() {
    _itemSizeController.close();
    _selectedController.close();
  }
}

class ItemSizeChange {
  final item;
  final Size size;

  ItemSizeChange(this.item, this.size);
}

class ItemSelectedChange {
  final item;
  final int index;

  ItemSelectedChange(this.item, this.index);
}

class SpinChange {
  /// Whether the spin is the next or the previous item.
  final bool next;

  SpinChange(this.next);
}
