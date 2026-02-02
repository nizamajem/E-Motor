import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> hasInternetConnection() async {
  final results = await Connectivity().checkConnectivity();
  return results.isNotEmpty && !results.contains(ConnectivityResult.none);
}
