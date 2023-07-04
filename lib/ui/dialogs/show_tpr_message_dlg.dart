import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tipitaka_pali/business_logic/models/tpr_message.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/ui/screens/settings/download_view.dart';

// stateful widget needed for switch.
// is here in the same file for ease..

Future<void> showWhatsNewDialog(
    BuildContext context, TprMessage tprMessage) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return WhatsNewDialog(tprMessage: tprMessage);
    },
  );
}

class WhatsNewDialog extends StatefulWidget {
  final TprMessage tprMessage;

  WhatsNewDialog({required this.tprMessage});

  @override
  _WhatsNewDialogState createState() => _WhatsNewDialogState();
}

class _WhatsNewDialogState extends State<WhatsNewDialog> {
  bool _showWhatsNew = Prefs.showWhatsNew; // use initial value from Prefs

  @override
  Widget build(BuildContext context) {
    String osInfo = "";
    if (Platform.isAndroid) {
      osInfo =
          "You can update to Android Version: ${widget.tprMessage.androidVersion}\n"
          "\tDPD without extension: ${widget.tprMessage.androidPeuDate}\n"
          "\tPEU without extension: ${widget.tprMessage.androidDpdDate}\n";
    }
    if (Platform.isWindows) {
      osInfo =
          "You can update to Windows Version: ${widget.tprMessage.windowsVersion}\n"
          "\tDPD without extension: ${widget.tprMessage.windowsPeuDate}\n"
          "\tPEU without extension: ${widget.tprMessage.windowsDpdDate}\n";
    }
    if (Platform.isLinux) {
      osInfo =
          "You can update to Linux Version: ${widget.tprMessage.linuxVersion}\n"
          "\tDPD without extension: ${widget.tprMessage.linuxPeuDate}\n"
          "\tPEU without extension: ${widget.tprMessage.linuxDpdDate}\n";
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppBar(
            title: Text(AppLocalizations.of(context)!.whatsNew),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          Column(
            children: [
              Text("Installed Version: ${Prefs.versionNumber}"),
              Text(osInfo),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(widget.tprMessage.generalMessage),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(AppLocalizations.of(context)!.showWhatsNew),
              Switch(
                onChanged: (value) {
                  setState(() {
                    _showWhatsNew = value;
                    Prefs.showWhatsNew = value; // Update the Prefs here
                  });
                },
                value: _showWhatsNew,
              ),
            ],
          ),
          ButtonBar(
            children: [
              TextButton(
                child: Text(AppLocalizations.of(context)!.extensions),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DownloadView(),
                    ),
                  );
                },
              ),
              TextButton(
                child: Text(AppLocalizations.of(context)!.home),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
