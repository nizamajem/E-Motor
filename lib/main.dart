import 'package:flutter/material.dart';

import 'app.dart';
import 'core/session/session_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionManager.instance.loadFromStorage();
  runApp(const EMotorApp());
}
