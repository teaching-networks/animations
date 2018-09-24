import 'package:angular/angular.dart';
import 'package:hm_animations/src/util/network/network_client.dart';

@Injectable()
class NetworkService {

  NetworkClient _client = NetworkClient();

  NetworkClient get client => _client;

}