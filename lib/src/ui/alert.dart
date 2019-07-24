import 'package:flutter/material.dart';

Future alert(BuildContext context, Widget title, String message) async {
  return showDialog(
    context: context,
    barrierDismissible: true, // user must tap button for close dialog!
    builder: (BuildContext context) {
      return AlertDialog(
        contentPadding:
            EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: title,
        content: Wrap(
          children: <Widget>[
            Text(message),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: <Widget>[
            //     FlatButton(
            //       child: const Text(
            //         'OK',
            //         style: TextStyle(color: Colors.blue),
            //       ),
            //       onPressed: () async {
            //         Navigator.pop(context);
            //       },
            //     ),
            //   ],
            // )
          ],
        ),
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
        contentPadding:
            EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: title,
        content: Wrap(
          children: <Widget>[
            content,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                FlatButton(
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed: () async {
                    await confirmAction();
                  },
                ),
                FlatButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () async {
                    await cancelAction();
                  },
                ),
              ],
            )
          ],
        ),
      );
    },
  );
}
