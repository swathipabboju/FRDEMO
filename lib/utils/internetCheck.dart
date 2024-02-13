import 'package:connectivity_plus/connectivity_plus.dart';
class InternetCheck {
  
  Future<bool> hasInternetConnection() async {
    var result = await Connectivity().checkConnectivity();
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi;
  }
}