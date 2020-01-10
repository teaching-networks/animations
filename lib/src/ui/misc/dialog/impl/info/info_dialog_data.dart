/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:meta/meta.dart';

/// Data for the input dialog.
class InfoDialogData {
  /// Title of the info dialog.
  final String title;

  /// Message of the info dialog.
  final String message;

  /// Create data.
  InfoDialogData({
    @required this.title,
    @required this.message,
  });
}
