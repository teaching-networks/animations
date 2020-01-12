/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';

/// Item used in a legend.
class LegendItem {
  /// Color to be explained.
  final Color color;

  /// Text explaining the colors meaning.
  final String text;

  /// Create item.
  LegendItem({
    this.color,
    this.text,
  });
}

/// Legend item gettings its labels from a message object.
class MessageLegendItem implements LegendItem {
  /// Color to be explained.
  final Color color;

  /// Message explaining the colors meaning.
  final Message msg;

  @override
  String get text => msg.toString();

  /// Create item.
  MessageLegendItem({
    this.color,
    this.msg,
  });
}
