import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';

abstract class DNSQueryType {
  final Message _name;

  DNSQueryType(this._name);

  String get name => _name.toString();

  int get id;
}

class RecursiveDNSQueryType extends DNSQueryType {
  RecursiveDNSQueryType(Message name) : super(name);

  int get id => 1;
}

class IterativeDNSQueryType extends DNSQueryType {
  IterativeDNSQueryType(Message name) : super(name);

  int get id => 2;
}
