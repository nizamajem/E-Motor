import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_motion.dart';

Future<void> showFindNoConnectionDialog(BuildContext context) async {
  StreamSubscription<List<ConnectivityResult>>? sub;
  try {
    await showAppDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        sub ??= Connectivity().onConnectivityChanged.listen((results) {
          if (!dialogContext.mounted) return;
          final hasInternet =
              results.isNotEmpty && !results.contains(ConnectivityResult.none);

          if (hasInternet) {
            if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
              Navigator.of(dialogContext, rootNavigator: true).pop();
            }
          }
        });

        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(strokeWidth: 2.6),
                  const SizedBox(height: 14),
                  Text(
                    'Menunggu koneksi internet\nuntuk mencari kendaraan...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  } finally {
    await sub?.cancel();
  }
}
