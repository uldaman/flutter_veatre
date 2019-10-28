import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bip_key_derivation/bip_key_derivation.dart';
import 'package:veatre/common/globals.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/recoveryPhraseGeneration.dart';

class CreateWallet extends StatefulWidget {
  final String rootRouteName;

  CreateWallet({
    Key key,
    @required this.rootRouteName,
  }) : super(key: key);

  _CreateWalletState createState() => _CreateWalletState();
}

class _CreateWalletState extends State<CreateWallet> {
  TextEditingController walletNameController;
  String address;
  String walletName = '';
  String mnemonic;
  bool isCopied = false;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await generateWalletName();
    String mnemonicWords = await BipKeyDerivation.generateRandomMnemonic(128);
    String addr = await addressFrom(mnemonicWords);
    setState(() {
      address = addr;
      mnemonic = mnemonicWords;
      isInitialized = true;
    });
  }

  Future<void> generateWalletName() async {
    int count = await WalletStorage.count() + 1;
    bool hasName = false;
    do {
      final name = "Account$count";
      hasName = await WalletStorage.hasName(name);
      if (hasName) {
        count++;
      } else {
        walletNameController = TextEditingController(text: name);
        setState(() {
          walletName = name;
        });
      }
    } while (hasName);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: ProgressHUD(
          child: SafeArea(
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
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
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
                                        color: Theme.of(context)
                                            .textTheme
                                            .title
                                            .color,
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
                                        textField(
                                          controller: walletNameController,
                                          hitText: 'Input',
                                        ),
                                      ],
                                    ), confirmAction: () async {
                                  String name = walletNameController.text;
                                  if (name.isEmpty) {
                                    return alert(
                                      context,
                                      Text('Invalid wallet name'),
                                      "wallet name can't be empty",
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
                              color: Theme.of(context).textTheme.title.color,
                              height: 2,
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  shotHex(address),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).textTheme.title.color,
                                    fontSize: 16,
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
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Card(
                        color: Theme.of(context).primaryColor,
                        child: new QrImage(
                          padding: EdgeInsets.all(40),
                          data: "0x${address ?? ''}",
                          size: MediaQuery.of(context).size.width - 200,
                          foregroundColor:
                              Theme.of(context).primaryTextTheme.title.color,
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
                        width: MediaQuery.of(context).size.width - 200,
                        height: 44,
                        child: FlatButton(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .title
                                  .color,
                            ),
                          ),
                          child: Text('Copy address'),
                          onPressed: () async {
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
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 200,
                    height: 46,
                    child: FlatButton(
                      color: Theme.of(context).textTheme.title.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        side: BorderSide(
                          color: Theme.of(context).textTheme.title.color,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Backup Now',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () async {
                        await WalletStorage.saveWallet(
                          address,
                          walletName,
                          mnemonic,
                          Globals.masterPasscodes,
                        );
                        await Navigator.push(
                          context,
                          new MaterialPageRoute(
                            builder: (context) => new RecoveryPhraseGeneration(
                              rootRouteName: widget.rootRouteName,
                              mnemonic: mnemonic,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 170,
                  height: 46,
                  child: FlatButton(
                    child: Text(
                      'Skip Now',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    color: Colors.transparent,
                    onPressed: () async {
                      await WalletStorage.saveWallet(
                        address,
                        walletName,
                        mnemonic,
                        Globals.masterPasscodes,
                      );
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
          isLoading: !isInitialized,
        ),
      ),
      onWillPop: () async {
        return !Navigator.of(context).userGestureInProgress;
      },
    );
  }

  TextField textField({
    TextEditingController controller,
    String hitText,
    String errorText,
  }) {
    return TextField(
      controller: controller,
      maxLength: 10,
      autofocus: true,
      decoration: InputDecoration(
        hintText: hitText,
        errorText: errorText,
      ),
      style: Theme.of(context).textTheme.body1,
    );
  }
}
