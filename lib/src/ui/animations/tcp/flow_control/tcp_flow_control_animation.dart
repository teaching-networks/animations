import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/shared/packet_line/packet_line.dart';
import 'package:hm_animations/src/ui/animations/tcp/flow_control/buffer/buffer_window.dart';
import 'package:hm_animations/src/ui/animations/tcp/flow_control/buffer/receiver_buffer_window.dart';
import 'package:hm_animations/src/ui/animations/tcp/flow_control/buffer/sender_buffer_window.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/canvas_pausable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

/// Animation showing the TCP flow control mechanism.
@Component(
    selector: "tcp-flow-control-animation",
    templateUrl: "tcp_flow_control_animation.html",
    styleUrls: ["tcp_flow_control_animation.css"],
    directives: [coreDirectives, CanvasComponent, MaterialButtonComponent, MaterialIconComponent, MaterialAutoSuggestInputComponent, MaterialSliderComponent],
    pipes: [I18nPipe])
class TCPFlowControlAnimation extends CanvasAnimation with CanvasPausableMixin implements OnInit, OnDestroy {
  final I18nService _i18n;

  /// Buffer window of the sender.
  BufferWindow _senderWindow;

  /// Buffer window of the receiver.
  BufferWindow _receiverWindow;

  /// Size of the file to transmit.
  int fileSize = 4096;

  /// Size of the buffer of sender and receiver (in bytes).
  int bufferSize = 2048;

  /// Speed measure of the animation (milliseconds).
  int speed = 1000;

  /// Suggestions for the file size.
  List<String> fileSizeSuggestions = ["4 KB", "8 KB", "16 KB"];

  /// Suggestions for the buffer size.
  List<String> bufferSizeSuggestions = ["2 KB", "4 KB"];

  /// Packet line representing a connection between sender and receiver.
  PacketLine _packetLine;

  /// Left packet info.
  String packetInfoLeft = "";

  /// Right packet info.
  String packetInfoRight = "";

  /// Temporary stream subscription.
  StreamSubscription<void> _sub;

  /// Whether to pause the animation.
  bool pause = false;

  /// Icon of a host computer.
  ImageElement _hostIcon = ImageElement(src: "img/animation/host_icon.svg");
  static const double _HOST_ICON_ASPECT_RATIO = 232.28 / 142.6;

  TCPFlowControlAnimation(this._i18n) {
    _reset();
  }

  /// Reset the animation.
  void _reset() {
    if (isPaused) {
      switchPause();
    }

    var dataLabel = _i18n.get("tcp-flow-control-animation.data");
    var bufferLabel = _i18n.get("tcp-flow-control-animation.buffer");

    _senderWindow = SenderBufferWindow(dataSize: fileSize, bufferSize: bufferSize, speed: realSpeed, dataLabel: dataLabel, bufferLabel: bufferLabel);
    _receiverWindow = ReceiverBufferWindow(dataSize: fileSize, bufferSize: bufferSize, speed: realSpeed, dataLabel: dataLabel, bufferLabel: bufferLabel);
    _packetLine =
        PacketLine(duration: Duration(milliseconds: realSpeed), onArrival: (id, color, forward, data) => onPacketLineArrival(id, color, forward, data));
  }

  int get realSpeed => 5000 - speed;

  @override
  void ngOnInit() {}

  @override
  void ngOnDestroy() {
    if (_sub != null) {
      _sub.cancel();
    }
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    double windowSize = size.height / 2;
    double iconHeight = windowSize / 2;
    double iconWidth = iconHeight * _HOST_ICON_ASPECT_RATIO;
    double panelHeight = windowSize + iconHeight;

    double iconY = size.height / 2 - panelHeight / 2;
    double windowY = iconY + iconHeight;

    context.font = "${displayUnit * 2}px sans-serif";

    context.drawImageToRect(_hostIcon, Rectangle(windowSize / 2 - iconWidth / 2, iconY, iconWidth, iconHeight));
    _senderWindow.render(context, Rectangle(0.0, windowY, windowSize, windowSize), timestamp);

    context.drawImageToRect(_hostIcon, Rectangle(size.width - windowSize / 2 - iconWidth / 2, iconY, iconWidth, iconHeight));
    _receiverWindow.render(context, Rectangle(size.width - windowSize, windowY, windowSize, windowSize), timestamp);

    double packetLineHeight = windowSize / 5;
    double packetLineWidth = size.width - 2 * windowSize;
    _packetLine.render(context, Rectangle(windowSize, windowY + windowSize - packetLineHeight, packetLineWidth, packetLineHeight), timestamp);

    context.textAlign = "center";
    context.textBaseline = "bottom";

    double packetInfoWidth = size.width - 2 * windowSize;
    double packetInfoY = windowY + windowSize - packetLineHeight - displayUnit * 2;

    context.fillText(packetInfoLeft, windowSize + packetInfoWidth / 3, packetInfoY, packetInfoWidth / 2);
    context.fillText(packetInfoRight, windowSize + packetInfoWidth / 3 * 2, packetInfoY, packetInfoWidth / 2);
  }

  /// What should happen when a packet arrives at the end of the packet line.
  void onPacketLineArrival(int packetID, Color color, bool forward, Object data) {
    if (forward) {
      _onReceiverReceivedPacket(data as SendData);
    } else {
      _onSenderReceivedPacket(data as ResponseData);
    }
  }

  /// What to do when the receiver received a packet with [sendData].
  void _onReceiverReceivedPacket(SendData sendData) {
    int remainingSizeInBuffer = ((1.0 - _receiverWindow.bufferProgress.actual) * _receiverWindow.bufferSize).toInt();
    int acknowledgementNumber = sendData.sequenceNumber;

    if (remainingSizeInBuffer > 0 && sendData.size > 1) {
      _receiverWindow.fillBuffer(sendData.size / _receiverWindow.bufferSize);

      // Wait until buffer is full.
      _sub = _receiverWindow.bufferStateChanged.listen((_) {
        _sub.cancel();

        remainingSizeInBuffer = ((1.0 - _receiverWindow.bufferProgress.actual) * _receiverWindow.bufferSize).toInt();
        acknowledgementNumber = sendData.sequenceNumber + sendData.size;

        _emitResponseDataPacket(Colors.CORAL, ResponseData(acknowledgementNumber, remainingSizeInBuffer));
      });
    } else {
      _emitResponseDataPacket(Colors.CORAL, ResponseData(acknowledgementNumber, remainingSizeInBuffer));
    }
  }

  /// Emit a [responseData] packet to the sender on the packet line.
  void _emitResponseDataPacket(Color color, ResponseData responseData) {
    _packetLine.emit(color: color, forward: false, data: responseData);

    packetInfoLeft = "ACK: ${responseData.acknowledgementNumber}";
    packetInfoRight = "WIN: ${responseData.windowSize}";
  }

  /// What to do when the sender received a packet with [responseData].
  void _onSenderReceivedPacket(ResponseData responseData) {
    bool isBufferEmpty = _senderWindow.bufferProgress.actual == 0.0;

    if (isBufferEmpty) {
      // Fill sender buffer again.
      _senderWindow.fillBuffer();

      // Wait until buffer is full.
      _sub = _senderWindow.bufferStateChanged.listen((_) {
        _sub.cancel();

        _senderSendPacket(responseData);
      });
    } else {
      _senderSendPacket(responseData);
    }
  }

  /// Send packet from sender to receiver.
  void _senderSendPacket(ResponseData responseData) {
    int sizeInBuffer = (_senderWindow.bufferProgress.actual * _senderWindow.bufferSize).round();

    if (sizeInBuffer > 0) {
      if (responseData.windowSize > 0) {
        // Now send the data in buffer to receiver.
        _senderWindow.clearBuffer();

        // Wait until the buffer is empty.
        _sub = _senderWindow.bufferStateChanged.listen((_) {
          _sub.cancel();

          // Send new data.
          _emitSendDataPacket(Colors.SLATE_GREY, SendData(sizeInBuffer, responseData.acknowledgementNumber));
        });
      } else {
        // Send query packet with size 1
        _emitSendDataPacket(Colors.CORAL, SendData(1, responseData.acknowledgementNumber));
      }
    }
  }

  /// Emit SendData packet [dataToSend] on packet line.
  void _emitSendDataPacket(Color color, SendData dataToSend) {
    _packetLine.emit(color: color, forward: true, data: dataToSend);

    packetInfoLeft = "SIZE: ${dataToSend.size}";
    packetInfoRight = "SEQ: ${dataToSend.sequenceNumber}";
  }

  /// Start the animation.
  void start() {
    _reset();

    _senderWindow.fillBuffer();

    // Wait until buffer full.
    _sub = _senderWindow.bufferStateChanged.listen((_) {
      _sub.cancel();

      int sizeInBuffer = (_senderWindow.bufferProgress.actual * _senderWindow.bufferSize).round();

      _senderWindow.clearBuffer();
      // Wait until buffer cleared.
      _sub = _senderWindow.bufferStateChanged.listen((_) {
        _sub.cancel();

        _emitSendDataPacket(Colors.SLATE_GREY, SendData(sizeInBuffer, 0));
      });
    });
  }

  @override
  void switchPauseSubAnimations() {
    _packetLine.switchPause();

    _senderWindow.switchPause();
    _receiverWindow.switchPause();
  }

  @override
  void unpaused(num timestampDifference) {
    // Do nothing.
  }

  String get fileSizeLabel => "${(fileSize / 1024).round()}";

  String get bufferSizeLabel => "${(bufferSize / 1024).round()}";

  /// What should happen in case the file size input changes.
  void onFileSizeChange(String newFileSize) {
    int newSize = parseSize(newFileSize);

    if (newSize != null) {
      fileSize = newSize * 1024;
    }
  }

  /// What should happen in case the buffer size input changes.
  void onBufferSizeChange(String newBufferSize) {
    int newSize = parseSize(newBufferSize);

    if (newSize != null) {
      bufferSize = newSize * 1024;
    }
  }

  /// Get the parsed number from the passed string or null if not parsable.
  int parseSize(String newSize) {
    newSize = newSize.trimLeft();

    if (newSize != null && newSize.isNotEmpty) {
      for (int i = 0; i < newSize.codeUnits.length; i++) {
        var codeUnit = newSize.codeUnitAt(i);

        if (!isCodeUnitNumeric(codeUnit)) {
          newSize = newSize.substring(0, i);
          break;
        }
      }

      return int.tryParse(newSize, radix: 10);
    }

    return null;
  }

  /// Whether a passed code unit is numeric (in range 0-9).
  bool isCodeUnitNumeric(int codeUnit) => codeUnit >= 48 && codeUnit <= 57;

  double get aspectRatio => 2.0;
}

/// Data transmitted via packets from sender to receiver.
class SendData {
  /// Size of the packet data in bytes.
  final int size;

  /// Sequencenumber.
  final int sequenceNumber;

  SendData(this.size, this.sequenceNumber);
}

/// Data transmitted via packets from receiver to sender.
class ResponseData {
  /// Acknowledgement number for the last packet.
  final int acknowledgementNumber;

  /// Remaining size in the receivers buffer window.
  final int windowSize;

  ResponseData(this.acknowledgementNumber, this.windowSize);
}
