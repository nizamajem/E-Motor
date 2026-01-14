import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/localization/app_localizations.dart';

enum EndRentalNoticeType {
  turnOffRequired,
  checkingStatus,
}

class EndRentalNoticeDialog extends StatelessWidget {
  const EndRentalNoticeDialog({
    super.key,
    required this.type,
  });

  final EndRentalNoticeType type;

  static Future<void> show(
    BuildContext context, {
    required EndRentalNoticeType type,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => EndRentalNoticeDialog(type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTurnOff = type == EndRentalNoticeType.turnOffRequired;
    final accent = isTurnOff ? const Color(0xFFFFA45B) : const Color(0xFF2C7BFE);
    final title = isTurnOff ? l10n.turnOffBeforeEndTitle : l10n.checkingEmotorTitle;
    final body = isTurnOff ? l10n.turnOffBeforeEndBody : l10n.checkingEmotorBody;
    final icon = isTurnOff ? Icons.power_settings_new_rounded : Icons.sync_rounded;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.8,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  textStyle: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(l10n.ok),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
