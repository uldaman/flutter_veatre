import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/ui/commonComponents.dart';

class ImportWalletGeneration extends StatefulWidget {
  final String address;
  final String defaultWalletName;
  final String rootRouteName;

  ImportWalletGeneration({
    Key key,
    @required this.address,
    @required this.defaultWalletName,
    @required this.rootRouteName,
  }) : super(key: key);

  _ImportWalletGenerationState createState() => _ImportWalletGenerationState();
}

class _ImportWalletGenerationState extends State<ImportWalletGeneration> {
  TextEditingController walletNameController;
  String address;
  String walletName;
  bool isCopied = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocus);
    address = widget.address;
    walletName = widget.defaultWalletName;
    walletNameController =
        TextEditingController(text: widget.defaultWalletName);
  }

  void _handleFocus() {
    if (_focusNode.hasFocus) {
      final text = walletNameController.text;
      walletNameController.value = walletNameController.value.copyWith(
        text: text,
        selection: TextSelection(baseOffset: 0, extentOffset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(left: 30, top: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Congratulation',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 30,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width - 100,
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(right: 15),
                    child: Picasso(
                      '0x$address',
                      size: 80,
                      borderRadius: 10,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        FlatButton(
                          padding: EdgeInsets.all(0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  walletName,
                                  textAlign: TextAlign.left,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              Icon(Icons.edit),
                            ],
                          ),
                          onPressed: () async {
                            await customAlert(context,
                                title: Text('Wallet name'),
                                content: Column(
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 10),
                                      child: Text(
                                        'input a name which can help you identify the wallet',
                                      ),
                                    ),
                                    walletNameTextField(
                                      controller: walletNameController,
                                      hitText: 'Input',
                                      focusNode: _focusNode,
                                    ),
                                  ],
                                ), confirmAction: () async {
                              String name = walletNameController.text;
                              if (name.isEmpty) {
                                return alert(
                                  context,
                                  Text('Invalid wallet name'),
                                  "wallet can't be empty",
                                );
                              }
                              Navigator.pop(context);
                              setState(() {
                                walletName = name;
                              });
                            });
                          },
                        ),
                        Divider(
                          thickness: 1,
                          height: 1,
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              '0x${abbreviate(address)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    Theme.of(context).textTheme.display2.color,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Card(
                  child: new QrImage(
                    padding: EdgeInsets.all(40),
                    data: "0x${address ?? ''}",
                    size: MediaQuery.of(context).size.width - 150,
                    backgroundColor: Theme.of(context).backgroundColor,
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: Center(
                    child: isCopied
                        ? Card(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5)),
                              side: BorderSide.none,
                            ),
                            color: Colors.grey[200],
                            child: Container(
                              child: Text(
                                'copied',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.amber),
                              ),
                              padding: EdgeInsets.all(8),
                            ),
                          )
                        : Text(''),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 150,
                  height: 44,
                  child: commonButton(
                    context,
                    'Copy address',
                    () async {
                      await Clipboard.setData(
                          new ClipboardData(text: '0x' + address));
                      setState(() {
                        isCopied = true;
                      });
                      await Future.delayed(Duration(seconds: 1));
                      setState(() {
                        isCopied = false;
                      });
                    },
                    color: Colors.transparent,
                    textColor: Theme.of(context).primaryTextTheme.title.color,
                    side: BorderSide(width: 1),
                  ),
                )
              ],
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 60,
                    height: 44,
                    child: commonButton(
                      context,
                      'Done',
                      () async {
                        await WalletStorage.updateName(address, walletName);
                        Navigator.popUntil(
                          context,
                          ModalRoute.withName(widget.rootRouteName),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
