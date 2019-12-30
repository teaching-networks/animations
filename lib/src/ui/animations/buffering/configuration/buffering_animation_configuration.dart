/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

/// Configuration for the buffering animation.
class BufferingAnimationConfiguration {
  /// The default bit rate (in bit/s).
  static const int default_bit_rate = 5000000;

  /// The default buffer size (in received packets).
  static const int default_buffer_size = 2;

  /// The default mean network rate (in bit/s).
  static const int default_mean_network_rate = 16000000;

  /// The default network rate variance (in bit/s).
  static const int default_network_rate_variance = 5000000;

  /// Constant bit rate of the media to stream (bit/s).
  int bitRate;

  /// Size of the playout buffer (in received packets).
  int bufferSize;

  /// Mean network rate (in bit/s).
  int meanNetworkRate;

  /// Network rate variance (in bit/s).
  int networkRateVariance;

  /// Seed used by the random number generator of the animation.
  int seed;

  /// Create configuration.
  BufferingAnimationConfiguration({
    this.bitRate = default_bit_rate,
    this.bufferSize = default_buffer_size,
    this.meanNetworkRate = default_mean_network_rate,
    this.networkRateVariance = default_network_rate_variance,
    this.seed = 0,
  });

  /// Convert the configuration to JSON.
  Map<String, dynamic> toJson() {
    return {
      "bit_rate": bitRate,
      "buffer_size": bufferSize,
      "mean_network_rate": meanNetworkRate,
      "network_rate_variance": networkRateVariance,
      "seed": seed,
    };
  }

  /// Convert the passed JSON formed map to this object.
  static BufferingAnimationConfiguration fromJson(Map<String, dynamic> json) {
    return BufferingAnimationConfiguration(
      bitRate: json["bit_rate"],
      bufferSize: json["buffer_size"],
      meanNetworkRate: json["mean_network_rate"],
      networkRateVariance: json["network_rate_variance"],
      seed: json["seed"],
    );
  }
}
