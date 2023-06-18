//do reset stuff
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../services/prefs.dart';
import 'confirm_dialog.dart';

doResetDialog(BuildContext context) async {
  final result = await _getConfirmataion(context);
  if (result == OkCancelAction.ok) {
    Prefs.instance.clear();
    await _showMyDialog(context);
  }
}

Future<OkCancelAction?> _getConfirmataion(BuildContext context) async {
  String msg =
      "${AppLocalizations.of(context)!.areYouSureReset}\n\nDir=${Prefs.databaseDirPath}";
  return await showDialog<OkCancelAction>(
      context: context,
      builder: (context) {
        return ConfirmDialog(
          title: AppLocalizations.of(context)!.confirmation,
          message: msg,
          okLabel: AppLocalizations.of(context)!.delete,
          cancelLabel: AppLocalizations.of(context)!.cancel,
        );
      });
}

// A function that shows an alert dialog with a message
Future<void> _showMyDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.alert),
        content: Text(AppLocalizations.of(context)!.pleaseCloseRestart),
        actions: <Widget>[
          TextButton(
            child: Text(AppLocalizations.of(context)!.ok),
            onPressed: () {
              // Dismiss the dialog
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
