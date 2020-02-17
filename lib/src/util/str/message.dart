import 'package:meta/meta.dart';

/// A message is a wrapper for a string value.
abstract class Message {
  /// Get the messages value.
  String get value;

  @override
  String toString() {
    return value;
  }
}

/// Simple message implementation.
class Msg extends Message {
  /// Value of the message.
  final String value;

  /// Create Msg.
  Msg(this.value);
}

/// An identifiable message.
class IdMessage<I> extends Message {
  /// Identifier of the message.
  I identifier;

  /// The content of the message.
  String value;

  /// Create new message.
  IdMessage({
    @required this.identifier,
    this.value = "",
  });

  /// Create empty message.
  IdMessage.empty({
    @required I identifier,
  }) : this(identifier: identifier, value: "");

  /// Create filled message without key.
  IdMessage.from(this.value);
}
