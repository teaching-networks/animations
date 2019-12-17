/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/layout.dart';
import 'package:hm_animations/src/util/size.dart';
import 'package:meta/meta.dart';

/// Layout positioning its children in a grid.
/// Cell sizes are set by using the child drawable size.
class GridLayout extends Layout {
  /// Cells positioned in the grid.
  List<CellSpec> cells;

  /// Offset for each row.
  List<double> _rowOffsets;

  /// Offset for each column.
  List<double> _columnOffsets;

  /// Children view to access drawables quickly.
  List<Drawable> _childrenView;

  /// Lookup of the cell specifications by row and column.
  List<List<CellSpec>> _lookup;

  /// Cells that span only one row and column.
  List<CellSpec> _singleRowColumnCells;

  /// Cells that span multiple rows/columns.
  List<CellSpec> _multiRowColumnCells;

  /// Create layout.
  GridLayout({
    Drawable parent,
    @required this.cells,
  })  : _childrenView = cells.map((c) => c.drawable).toList(growable: false),
        super(parent: parent) {
    _init();
  }

  /// Count of rows in the grid.
  int get rows => _lookup.length;

  /// Could of columns in the grid.
  int get columns => _lookup.isEmpty ? 0 : _lookup.first.length;

  /// Initialize the layout.
  void _init() {
    _recalculateGrid();
    _recalculateLayout();
  }

  /// Recalculate the grid.
  void _recalculateGrid() {
    // Calculate the needed amount of rows and columns
    int rows = 0;
    int columns = 0;
    for (CellSpec spec in cells) {
      int maxRows = spec.row + spec.rowSpan;
      int maxColumns = spec.column + spec.columnSpan;

      if (maxRows > rows) rows = maxRows;
      if (maxColumns > columns) columns = maxColumns;
    }

    // Prepare cell spec lookup by row and column
    _lookup = List<List<CellSpec>>(rows);
    for (int row = 0; row < rows; row++) {
      _lookup[row] = List<CellSpec>(columns);
    }

    // Fill lookup with cell specifications.
    _singleRowColumnCells = List<CellSpec>();
    _multiRowColumnCells = List<CellSpec>();
    for (CellSpec spec in cells) {
      if (spec.spansOverArea) {
        _multiRowColumnCells.add(spec);
      } else {
        _singleRowColumnCells.add(spec);
      }

      for (int row = spec.row; row < spec.row + spec.rowSpan; row++) {
        for (int column = spec.column; columns < spec.column + spec.columnSpan; column++) {
          if (row == spec.row && column == spec.column) {
            _lookup[row][column] = spec;
          } else {
            _lookup[row][column] = _CellSpecRef(spec);
          }
        }
      }
    }
  }

  /// Recalculate the layout.
  void _recalculateLayout() {
    assert(_lookup != null);

    List<double> rowSizes = List.filled(rows, 0);
    List<double> columnSizes = List.filled(columns, 0);

    // Find row and column sizes by cells that do not span multiple cells.
    for (CellSpec spec in _singleRowColumnCells) {
      Size size = spec.drawable.size;

      if (size.height > rowSizes[spec.row]) rowSizes[spec.row] = size.height;
      if (size.width > columnSizes[spec.column]) columnSizes[spec.column] = size.width;
    }

    // Adjust row and column sizes by cells that span multiple cells and do not have enough space.
    for (CellSpec spec in _multiRowColumnCells) {
      Size size = spec.drawable.size;

      double currentHeight = 0;
      for (int row = spec.row; row < spec.row + spec.rowSpan; row++) {
        currentHeight += rowSizes[row];
      }

      double currentWidth = 0;
      for (int column = spec.column; column < spec.column + spec.columnSpan; column++) {
        currentWidth += columnSizes[column];
      }

      if (size.height > currentHeight) {
        // Increase height of all affected rows
        double inc = (size.height - currentHeight) / spec.rowSpan;
        for (int row = spec.row; row < spec.row + spec.rowSpan; row++) {
          rowSizes[row] += inc;
        }
      }

      if (size.width > currentWidth) {
        // Increase width of all affected columns
        double inc = (size.width - currentWidth) / spec.columnSpan;
        for (int column = spec.column; column < spec.column + spec.columnSpan; column++) {
          columnSizes[column] += inc;
        }
      }
    }

    // Calculate row and column offsets using the row and column sizes
    _rowOffsets = List<double>(rows + 1);
    double value = 0;
    _rowOffsets.first = value;
    for (int row = 0; row < rows; row++) {
      value += rowSizes[row];
      _rowOffsets[row + 1] = value;
    }

    _columnOffsets = List<double>(columns + 1);
    value = 0;
    _columnOffsets.first = value;
    for (int column = 0; column < columns; column++) {
      value += columnSizes[column];
      _columnOffsets[column + 1] = value;
    }

    // Set bounds for all cells
    for (CellSpec spec in cells) {
      spec._setBounds(_getBoundsForCell(spec));
    }

    // Set drawable size
    setSize(
      width: _columnOffsets.last,
      height: _rowOffsets.last,
    );
  }

  /// Get the bounds for the passed cell.
  Rectangle<double> _getBoundsForCell(CellSpec spec) {
    return Rectangle<double>(
      _columnOffsets[spec.column],
      _rowOffsets[spec.row],
      _columnOffsets[spec.column + spec.columnSpan] - _columnOffsets[spec.column],
      _rowOffsets[spec.row + spec.rowSpan] - _rowOffsets[spec.row],
    );
  }

  @override
  List<Drawable> get children => _childrenView;

  @override
  void layout() {
    if (cells == null || cells.isEmpty) {
      return;
    }

    for (CellSpec spec in cells) {
      spec.drawable.render(
        ctx,
        lastPassTimestamp,
        x: spec.bounds.left + (spec.bounds.width - spec.drawable.size.width) / 2,
        y: spec.bounds.top + (spec.bounds.height - spec.drawable.size.height) / 2,
      );
    }
  }

  @override
  void onChildSizeChange(SizeChange change) {
    _recalculateLayout();
  }

  @override
  void onParentSizeChange(SizeChange change) {
    // Do nothing.
  }
}

/// Specification of a cell.
class CellSpec {
  /// Row of the cell (starts with 0).
  final int row;

  /// Column of the cell (starts with 0).
  final int column;

  /// How many rows this cell spans (minimum is 1).
  final int rowSpan;

  /// How many columns this cell spans (minimum is 1).
  final int columnSpan;

  /// Drawable to display in the cell.
  final Drawable drawable;

  /// Current bounds of the cell.
  Rectangle<double> _bounds;

  /// Create cell specification.
  CellSpec({
    @required this.row,
    @required this.column,
    this.rowSpan = 1,
    this.columnSpan = 1,
    @required this.drawable,
  }) {
    if (rowSpan < 1 || columnSpan < 1) {
      throw new Exception("Row and column spans need to be at least 1");
    }
  }

  /// Whether cell spans more than one row or columns.
  bool get spansOverArea => rowSpan > 1 || columnSpan > 1;

  /// Get the current bounds of the cell.
  Rectangle<double> get bounds => _bounds;

  /// Set the current bounds of the cell.
  void _setBounds(Rectangle<double> value) {
    _bounds = value;
  }
}

/// Reference to a cell specification.
class _CellSpecRef implements CellSpec {
  /// The cell specification this reference references to.
  final CellSpec referenced;

  /// Create reference to a cell specification.
  _CellSpecRef(this.referenced);

  @override
  int get column => referenced.column;

  @override
  int get columnSpan => referenced.columnSpan;

  @override
  Drawable get drawable => referenced.drawable;

  @override
  int get row => referenced.row;

  @override
  int get rowSpan => referenced.rowSpan;

  @override
  bool get spansOverArea => referenced.spansOverArea;

  @override
  void _setBounds(Rectangle<double> value) {
    throw new Exception("Cell spec reference does not support setting bounds");
  }

  @override
  Rectangle<double> get bounds => referenced.bounds;

  @override
  Rectangle<double> get _bounds => referenced._bounds;

  @override
  void set _bounds(Rectangle<double> __bounds) {
    referenced._bounds = __bounds;
  }
}
