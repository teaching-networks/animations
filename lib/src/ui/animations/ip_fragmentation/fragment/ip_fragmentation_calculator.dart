/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'ip_fragment.dart';

/// Calculator for fragmenting IP datagrams.
class IPFragmentationCalculator {
  /// Size of the IP header in bytes.
  static const int _ipHeaderSize = 20;

  /// Minimum MTU.
  static const int minMTU = 68;

  /// Maxmimum MTU.
  static const int maxMTU = 65535;

  /// Minimum datagram size.
  static const int minDatagramSize = 68;

  /// Maximum datagram size.
  static const int maxDatagramSize = 65535;

  /// Fragment the passed IP datagram specs to a list of fragments.
  /// [size] in bytes
  /// [maximumTransmissionUnit] in bytes
  List<IPFragment> fragment(int size, int maximumTransmissionUnit, int datagramID) {
    if (size < minDatagramSize) {
      throw new Exception("Passed datagram size ($size bytes) has to be greater or equal to $minDatagramSize bytes");
    }

    if (size > maxDatagramSize) {
      throw new Exception("Passed datagram size ($size bytes) has to be lower or equal to $maxDatagramSize bytes");
    }

    if (maximumTransmissionUnit < minMTU) {
      throw new Exception("Passed MTU (Maximum transmission unit) ($maximumTransmissionUnit bytes) must be greater or equal to $minMTU bytes");
    }

    if (maximumTransmissionUnit > maxMTU) {
      throw new Exception("Passed MTU (Maximum transmission unit) ($maximumTransmissionUnit bytes) must be lower or equal to $maxMTU bytes");
    }

    int dataSize = size - _ipHeaderSize;
    int mtuDataSize = (maximumTransmissionUnit - _ipHeaderSize) ~/ 8 * 8;

    double count = dataSize / mtuDataSize;
    int lastFragmentDataSize = count - count.floor() > 0 ? ((count - count.floor()) * mtuDataSize).round() : mtuDataSize;

    final fragments = List<IPFragment>(count.ceil());

    for (int i = 0; i < fragments.length; i++) {
      bool isLast = i == fragments.length - 1;

      fragments[i] = IPFragment(
        number: i + 1,
        id: datagramID,
        size: isLast ? lastFragmentDataSize : mtuDataSize,
        offset: (mtuDataSize * i) ~/ 8,
        moreFragments: !isLast,
      );
    }

    return fragments;
  }
}
