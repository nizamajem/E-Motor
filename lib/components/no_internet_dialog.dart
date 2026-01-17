import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/localization/app_localizations.dart';

Future<void> showNoInternetDialog(BuildContext context) async {
  late StreamSubscription<List<ConnectivityResult>> sub;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      sub = Connectivity().onConnectivityChanged.listen((results) {
        final hasInternet =
            results.isNotEmpty && !results.contains(ConnectivityResult.none);

        if (hasInternet) {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        }
      });

      return WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 46,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 14),
                Text(
                  AppLocalizations.of(context).errorNoInternet,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).noInternetDescription,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                const CircularProgressIndicator(strokeWidth: 2.8),
              ],
            ),
          ),
        ),
      );
    },
  );

  await sub.cancel();
}
