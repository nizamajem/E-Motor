import 'package:flutter/material.dart';

import 'app_motion.dart';

void showErrorSnack(BuildContext context, String message) {
  showAppSnackBar(context, message, isError: true);
}

void showInfoSnack(BuildContext context, String message) {
  showAppSnackBar(context, message);
}
