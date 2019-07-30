/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

enum ConnectionStepType {
  TCP_CONNECTION_ESTABLISHMENT,
  HTML_PAGE_REQUEST,
  OBJECT_REQUEST
}

/// Step in an connection.
abstract class ConnectionStep {

  static const ConnectionStep TCP_CONNECTION_ESTABLISHMENT = TCPConnectionEstablishmentStep();
  static const ConnectionStep HTML_PAGE_REQUEST = HTMLPageRequestStep();

  /// ConnectionStep type.
  final ConnectionStepType type;

  const ConnectionStep(this.type);

}

class TCPConnectionEstablishmentStep extends ConnectionStep {

  const TCPConnectionEstablishmentStep() : super(ConnectionStepType.TCP_CONNECTION_ESTABLISHMENT);

}

class HTMLPageRequestStep extends ConnectionStep {

  const HTMLPageRequestStep() : super(ConnectionStepType.HTML_PAGE_REQUEST);

}

class ObjectRequestStep extends ConnectionStep {

  /// Amount of RTTs this object is big.
  final double rtts;

  const ObjectRequestStep(this.rtts) : super(ConnectionStepType.OBJECT_REQUEST);

}
