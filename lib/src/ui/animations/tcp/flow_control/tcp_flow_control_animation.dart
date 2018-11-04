import 'dart:async';
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
    directives: [coreDirectives, CanvasComponent, MaterialButtonComponent],
    pipes: [I18nPipe])
class TCPFlowControlAnimation extends CanvasAnimation with CanvasPausableMixin implements OnInit, OnDestroy {
  final I18nService _i18n;

  /// Buffer window of the sender.
  BufferWindow _senderWindow;

  /// Buffer window of the receiver.
  BufferWindow _receiverWindow;

  int fileSize = 4096;
  int bufferSize = 2048;

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

  TCPFlowControlAnimation(this._i18n) {
    _reset();
  }

  /// Reset the animation.
  void _reset() {
    _senderWindow = SenderBufferWindow(); // TODO Set the file and buffer size in the constructor.
    _receiverWindow = ReceiverBufferWindow();
    _packetLine =
        PacketLine(duration: Duration(seconds: 1, milliseconds: 500), onArrival: (id, color, forward, data) => onPacketLineArrival(id, color, forward, data));
  }

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

    double windowSize = size.height;
    double windowY = 0.0;

    _senderWindow.render(context, Rectangle(0.0, windowY, windowSize, windowSize), timestamp);
    _receiverWindow.render(context, Rectangle(windowSize * 2, windowY, windowSize, windowSize), timestamp);

    double packetLineSize = windowSize / 5;
    _packetLine.render(context, Rectangle(windowSize, windowY + windowSize - packetLineSize, windowSize, packetLineSize), timestamp);

    context.textAlign = "center";
    context.textBaseline = "bottom";

    double packetInfoWidth = windowSize;
    double packetInfoY = windowY + windowSize - packetLineSize - displayUnit * 2;

    context.fillText(packetInfoLeft, windowSize + packetInfoWidth / 3, packetInfoY, packetInfoWidth / 2);
    context.fillText(packetInfoRight, windowSize + packetInfoWidth / 3 * 2, packetInfoY, packetInfoWidth / 2);
  }

  /// Get the canvas height.
  int get canvasHeight => (windowHeight * 0.8).round();

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
    print("Received: SIZE: ${sendData.size}, SEQ: ${sendData.sequenceNumber}");

    int remainingSizeInBuffer = ((1.0 - _receiverWindow.bufferProgress.actual) * _receiverWindow.bufferSize).toInt();
    int acknowledgementNumber = sendData.sequenceNumber;

    if (remainingSizeInBuffer > 0 && sendData.size > 1) {
      _receiverWindow.fillBuffer();

      // Wait until buffer is full.
      _sub = _receiverWindow.bufferFull.listen((_) {
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
    print("Received: ACK: ${responseData.acknowledgementNumber}, WINDOW_SIZE: ${responseData.windowSize}");

    bool isBufferFull = _senderWindow.bufferProgress.actual == 1.0;

    if (!isBufferFull) {
      // Fill sender buffer again.
      _senderWindow.fillBuffer();

      // Wait until buffer is full.
      _sub = _senderWindow.bufferFull.listen((_) {
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
        _sub = _senderWindow.bufferEmpty.listen((_) {
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
    _sub = _senderWindow.bufferFull.listen((_) {
      _sub.cancel();

      int sizeInBuffer = (_senderWindow.bufferProgress.actual * _senderWindow.bufferSize).round();

      _senderWindow.clearBuffer();
      // Wait until buffer cleared.
      _sub = _senderWindow.bufferEmpty.listen((_) {
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
