import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/localization/app_localizations.dart';
import 'app_motion.dart';

void showLoadingDialog(
  BuildContext context, {
  String? message,
  VoidCallback? onCancel,
  bool showClose = false,
}) {
  showAppDialog(
    context: context,
    barrierDismissible: showClose,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showClose)
                Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        onCancel?.call();
                      },
                      icon: const Icon(Icons.close),
                      iconSize: 18,
                      color: const Color(0xFF111827),
                      splashRadius: 18,
                    ),
                  ),
                ),
              const SizedBox(
                height: 32,
                width: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 14),
              Text(
                message ?? AppLocalizations.of(context).loadingProcessing,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void hideLoadingDialog(BuildContext context) {
  if (Navigator.of(context, rootNavigator: true).canPop()) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
