/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/util/str/message.dart';

abstract class DNSQueryType {
  final IdMessage<String> _name;

  DNSQueryType(this._name);

  String get name => _name.toString();

  int get id;
}

class RecursiveDNSQueryType extends DNSQueryType {
  RecursiveDNSQueryType(IdMessage<String> name) : super(name);

  int get id => 1;
}

class IterativeDNSQueryType extends DNSQueryType {
  IterativeDNSQueryType(IdMessage<String> name) : super(name);

  int get id => 2;
}
