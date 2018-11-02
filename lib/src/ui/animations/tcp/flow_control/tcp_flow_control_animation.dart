import 'dart:math';

import 'package:angular/angular.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/shared/packet_line/packet_line.dart';
import 'package:hm_animations/src/ui/animations/tcp/flow_control/buffer/buffer_window.dart';
import 'package:hm_animations/src/ui/animations/tcp/flow_control/buffer/receiver_buffer_window.dart';
import 'package:hm_animations/src/ui/animations/tcp/flow_control/buffer/sender_buffer_window.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

/// Animation showing the TCP flow control mechanism.
@Component(
    selector: "tcp-flow-control-animation",
    templateUrl: "tcp_flow_control_animation.html",
    styleUrls: ["tcp_flow_control_animation.css"],
    directives: [coreDirectives, CanvasComponent],
    pipes: [I18nPipe])
class TCPFlowControlAnimation extends CanvasAnimation implements OnInit {
  final I18nService _i18n;

  final BufferWindow _senderWindow = SenderBufferWindow();
  final BufferWindow _receiverWindow = ReceiverBufferWindow();

  int fileSize = 4096;
  int bufferSize = 2048;

  PacketLine _packetLine;

  TCPFlowControlAnimation(this._i18n) {
    _packetLine = PacketLine(onArrival: (id, color, forward, data) => onPacketLineArrival(id, color, forward, data));
  }

  @override
  void ngOnInit() {}

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    double windowSize = size.width / 3;
    double windowY = size.height / 2 - windowSize / 2;

    _senderWindow.render(context, Rectangle(0.0, windowY, windowSize, windowSize), timestamp);
    _receiverWindow.render(context, Rectangle(windowSize * 2, windowY, windowSize, windowSize), timestamp);

    double packetLineSize = windowSize / 5;
    _packetLine.render(context, Rectangle(windowSize, windowY + windowSize - packetLineSize, windowSize, packetLineSize), timestamp);
  }

  /// Get the canvas height.
  int get canvasHeight => (windowHeight * 0.8).round();

  /// What should happen when a packet arrives at the end of the packet line.
  void onPacketLineArrival(int packetID, Color color, bool forward, Object data) {
    if (forward) {
      SendData sendData = data as SendData;

      print("Received: SIZE: ${sendData.size}, SEQ: ${sendData.sequenceNumber}");

      int remainingSizeInBuffer = ((1.0 - _receiverWindow.bufferProgress.actual) * _receiverWindow.bufferSize).toInt();
      int acknowledgementNumber = sendData.sequenceNumber;

      if (remainingSizeInBuffer > 0 && sendData.size > 1) {
        _receiverWindow.fillBuffer();

        remainingSizeInBuffer = ((1.0 - _receiverWindow.bufferProgress.actual) * _receiverWindow.bufferSize).toInt();
        acknowledgementNumber = sendData.sequenceNumber + sendData.size;
      }

      _packetLine.emit(color: Colors.RED, forward: false, data: ResponseData(acknowledgementNumber, remainingSizeInBuffer));
    } else {
      // Fill sender buffer again.
      _senderWindow.fillBuffer();
      int sizeInBuffer = (_senderWindow.bufferProgress.actual * _senderWindow.bufferSize).round();

      ResponseData responseData = data as ResponseData;

      print("Received: ACK: ${responseData.acknowledgementNumber}, WINDOW_SIZE: ${responseData.windowSize}");

      if (sizeInBuffer > 0) {
        if (responseData.windowSize > 0) {
          // Now send the data in buffer to receiver.
          _senderWindow.clearBuffer();

          _packetLine.emit(color: Colors.SLATE_GREY, forward: true, data: SendData(sizeInBuffer, responseData.acknowledgementNumber));
        } else {
          // Send query packet with size 1
          _packetLine.emit(color: Colors.RED, forward: true, data: SendData(1, responseData.acknowledgementNumber));
        }
      }
    }
  }

  void test() {
    _senderWindow.fillBuffer();
  }

  void test2() {
    int sizeInBuffer = (_senderWindow.bufferProgress.actual * _senderWindow.bufferSize).round();
    _senderWindow.clearBuffer();

    _packetLine.emit(color: Colors.SLATE_GREY, forward: true, data: SendData(sizeInBuffer, 0));
  }
}

class SendData {
  /// Size of the packet data in bytes.
  final int size;

  /// Sequencenumber.
  final int sequenceNumber;

  SendData(this.size, this.sequenceNumber);
}

class ResponseData {
  /// Acknowledgement number for the last packet.
  final int acknowledgementNumber;

  /// Remaining size in the receivers buffer window.
  final int windowSize;

  ResponseData(this.acknowledgementNumber, this.windowSize);
}
