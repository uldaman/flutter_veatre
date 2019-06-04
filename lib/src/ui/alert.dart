import 'package:flutter/material.dart';

Future alert(BuildContext context, Widget title, String message) async {
  return showDialog(
    context: context,
    barrierDismissible: false, // user must tap button for close dialog!
    builder: (BuildContext context) {
      return AlertDialog(
        title: title,
        content: Text(message),
        actions: <Widget>[
          FlatButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          )
        ],
      );
    },
  );
}

Future customAlert(
  BuildContext context, {
  Widget title,
  Widget content,
  Future<void> Function() confirmAction,
  Future<void> Function() cancelAction,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: title,
        content: content,
        actions: <Widget>[
          FlatButton(
            child: const Text('OK'),
            onPressed: () async {
              await confirmAction();
            },
          ),
          FlatButton(
            child: const Text('Cancel'),
            onPressed: () async {
              await cancelAction();
            },
          ),
        ],
      );
    },
  );
}
