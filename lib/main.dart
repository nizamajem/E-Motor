import 'package:flutter/material.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/session/session_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionManager.instance.loadFromStorage();
  await ApiClient().refreshAccessToken();
  runApp(const EMotorApp());
}
