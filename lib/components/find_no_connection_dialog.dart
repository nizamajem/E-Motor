import 'dart:async';
import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';
import 'no_internet_dialog.dart';

Future<void> showFindNoConnectionDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  await showNoInternetDialog(
    context,
    titleOverride: l10n.findingConnectionTitle,
    messageOverride: l10n.findingConnectionBody,
  );
}
