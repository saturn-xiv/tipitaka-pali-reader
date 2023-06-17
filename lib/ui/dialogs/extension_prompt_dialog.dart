import 'package:flutter/material.dart';

class ExtensionPromptDialog extends StatelessWidget {
  final String message;

  const ExtensionPromptDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Extensions Found"),
      content: Text(message),
      actions: [
        TextButton(
          child: Text("Yes"),
          onPressed: () {
            Navigator.of(context).pop(true); // Return true to indicate install
          },
        ),
        TextButton(
          child: Text("No"),
          onPressed: () {
            Navigator.of(context)
                .pop(false); // Return false to indicate skip install
          },
        ),
      ],
    );
  }
}
