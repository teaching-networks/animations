import 'dart:async';

import 'package:hm_animations/src/ui/canvas/progress/progress.dart';

/// Object holding a progress [0.0; 1.0].
class MutableProgress implements Progress {

  /// Progress changes are emitted through this stream controller.
  StreamController<double> _progressChanges = StreamController<double>.broadcast(sync: false);

  /// Progress in range [0.0; 1.0].
  double _progress;

  /// Create new progress.
  MutableProgress({double progress = 0.0}) : _progress = progress;

  /// Stream used to listen to progress changes.
  Stream<double> get progressChanges => _progressChanges.stream;

  @override
  double get progress => _progress;

  set progress(double value) {
    if (value < 0.0 || value > 1.0) {
      throw new Exception("Progress cannot exceed range [0.0; 1.0]. Value was $value");
    }

    _progress = value;
    _progressChanges.add(_progress);
  }

  /// Set the progress the save way by checking if value is in range [0.0; 1.0].
  /// The progress will then be set to either 0.0 or 1.0 whichever is nearer to the value.
  set progressSave(double value) {
    if (value < 0.0) {
      progress = 0.0;
    } else if (value > 1.0) {
      progress = 1.0;
    } else {
      progress = value;
    }

    _progressChanges.add(_progress);
  }

}
