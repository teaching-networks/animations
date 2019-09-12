/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:angular/angular.dart';
import 'package:hm_animations/src/util/network/network_client.dart';

@Injectable()
class NetworkService {

  NetworkClient _client = NetworkClient();

  NetworkClient get client => _client;

}
