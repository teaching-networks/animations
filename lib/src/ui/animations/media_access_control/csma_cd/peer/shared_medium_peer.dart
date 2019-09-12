/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/medium/shared_medium.dart';

/// A participant on a shared medium.
abstract class SharedMediumPeer {
  /// Get shared medium peer is sending and listing on.
  SharedMedium getMedium();

  /// Set the listening state of the peer.
  void setListening(bool isListening);

  /// Check if the peer is currently listening.
  bool isListening();

  /// Set whether the medium is occupied.
  void setMediumOccupied(bool isOccupied);

  /// Whether the medium is occupied from the peers perception.
  bool isMediumOccupied();

  /// Set the sending state of the peer.
  void setSending(bool isSending);

  /// Whether the peer is currently sending.
  bool isSending();
}
