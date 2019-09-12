/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/progress/progress.dart';

/// Transform function for progress.
typedef double TransformFct(double p);

/// Transform a existing progress with this.
class ProgressTransform implements Progress {

  /// Delegate progress to transform.
  final Progress delegate;

  /// Function to transform progress with.
  final TransformFct transformFct;

  /// Create new progress transforming an existing one.
  ProgressTransform(this.delegate, this.transformFct);

  @override
  double get progress => transformFct(delegate.progress);

}
