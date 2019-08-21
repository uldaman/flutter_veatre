import 'package:flutter/material.dart';

Future alert(BuildContext context, Widget title, String message) async {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Theme.of(context).primaryColor,
        shape: Theme.of(context).cardTheme.shape,
        contentPadding:
            EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 24),
        title: title,
        content: Wrap(
          children: <Widget>[
            Text(
              message,
              style: TextStyle(color: Theme.of(context).textTheme.title.color),
            ),
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
  void Function() defauctAction = () {};
  Future<void> Function() cancel = cancelAction ?? defauctAction;
  Future<void> Function() ok = confirmAction ?? defauctAction;

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Theme.of(context).primaryColor,
        contentPadding:
            EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 12),
        shape: Theme.of(context).cardTheme.shape,
        title: title,
        content: Wrap(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: content,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                FlatButton(
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed: () async {
                    await ok();
                  },
                ),
                FlatButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () async {
                    await cancel();
                    Navigator.pop(context);
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
