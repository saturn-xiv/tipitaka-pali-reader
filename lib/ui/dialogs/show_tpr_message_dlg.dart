import 'package:flutter/material.dart';
import 'package:tipitaka_pali/business_logic/models/tpr_message.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void showTprMessageDialog(BuildContext context, TprMessage tprMessage) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.message),
        content: Text(tprMessage.generalMessage),
        actions: <Widget>[
          TextButton(
            child: Text(AppLocalizations.of(context)!.ok),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
