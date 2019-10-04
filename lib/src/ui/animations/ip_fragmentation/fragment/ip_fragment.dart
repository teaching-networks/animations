/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

/// Fragment created from IP fragmentation of a datagram.
class IPFragment {
  /// Number of the fragment.
  final int number;

  /// Datagram ID the fragments belong to.
  final int id;

  /// Size of the fragment data.
  final int size;

  /// Offset of the fragment data.
  /// It defines the preceding number of data bytes divided by 8.
  final int offset;

  /// Flag set when there are more fragments to follow for the same datagram.
  final bool moreFragments;

  /// Create fragment.
  IPFragment({
    this.number,
    this.id,
    this.size,
    this.offset,
    this.moreFragments,
  });

  @override
  String toString() {
    return "[$number] | ID: $id, size: $size, offset: $offset, moreFragments: $moreFragments";
  }
}
