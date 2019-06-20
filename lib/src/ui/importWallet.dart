import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:veatre/src/ui/alert.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/ui/progressHUD.dart';
import 'package:veatre/src/bip39/mnemonic.dart';
import 'package:veatre/src/models/keyStore.dart';
import 'package:veatre/src/storage/storage.dart';
import 'package:web3dart/crypto.dart';

class ImportWallet extends StatefulWidget {
  static final routeName = '/wallets/import';

  @override
  ImportWalletState createState() => ImportWalletState();
}

class ImportWalletState extends State<ImportWallet> {
  int currentPage = 0;
  bool loading = false;
  Decriptions decriptions;
  TextEditingController mnemonicController = TextEditingController();
  TextEditingController mnemonicWalletNameController = TextEditingController();
  TextEditingController mnemonicPasswordController = TextEditingController();
  TextEditingController keystoreController = TextEditingController();
  TextEditingController keystoreWalletNameController = TextEditingController();
  TextEditingController keystorePasswordController = TextEditingController();

  Future<WalletEntity> walletExisted(String address) async {
    List<WalletEntity> walletEntities = await WalletStorage.readAll();
    for (WalletEntity walletEntity in walletEntities) {
      if (walletEntity.keystore.address == address) {
        return walletEntity;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    PageController pageController = PageController(initialPage: currentPage);
    PageView pageView = PageView(
      scrollDirection: Axis.horizontal,
      controller: pageController,
      physics: new ClampingScrollPhysics(),
      onPageChanged: (int page) async {
        setState(() {
          this.currentPage = page;
        });
      },
      children: <Widget>[
        Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(top: 5, left: 5, right: 5),
                  child: Card(
                    child: Theme(
                      data: ThemeData(
                        primaryColor: Colors.blue,
                        primaryColorDark: Colors.blueAccent,
                      ),
                      child: TextFormField(
                        controller: mnemonicController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.lightBlue,
                            ),
                          ),
                          contentPadding: EdgeInsets.all(10),
                          hintText:
                              'Input your mnemonic phase which is splited by whitespace',
                        ),
                        maxLines: 30,
                      ),
                    ),
                  ),
                  height: 120,
                  width: MediaQuery.of(context).size.width,
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    height: 80,
                    margin: EdgeInsets.only(bottom: 10, top: 10),
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: Theme(
                      data: ThemeData(
                        primaryColor: Colors.blue,
                        primaryColorDark: Colors.blueAccent,
                      ),
                      child: TextField(
                        controller: mnemonicWalletNameController,
                        maxLength: 20,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.lightBlue,
                            ),
                          ),
                          hintText: 'wallet name',
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    height: 80,
                    margin: EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: Theme(
                      data: ThemeData(
                        primaryColor: Colors.blue,
                        primaryColorDark: Colors.blueAccent,
                      ),
                      child: TextField(
                        controller: mnemonicPasswordController,
                        maxLength: 20,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.lightBlue,
                            ),
                          ),
                          hintText: 'new password',
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
        Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(top: 5, left: 5, right: 5),
                  child: Card(
                    child: Theme(
                      data: ThemeData(
                        primaryColor: Colors.blue,
                        primaryColorDark: Colors.blueAccent,
                      ),
                      child: TextFormField(
                        controller: keystoreController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.lightBlue,
                            ),
                          ),
                          contentPadding: EdgeInsets.all(10),
                          hintText: 'Input your keystore',
                        ),
                        maxLines: 30,
                      ),
                    ),
                  ),
                  height: 120,
                  width: MediaQuery.of(context).size.width,
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    height: 80,
                    margin: EdgeInsets.only(bottom: 10, top: 10),
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: Theme(
                      data: ThemeData(
                        primaryColor: Colors.blue,
                        primaryColorDark: Colors.blueAccent,
                      ),
                      child: TextField(
                        controller: keystoreWalletNameController,
                        maxLength: 20,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.lightBlue,
                            ),
                          ),
                          hintText: 'wallet name',
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    height: 80,
                    margin: EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: Theme(
                      data: ThemeData(
                        primaryColor: Colors.blue,
                        primaryColorDark: Colors.blueAccent,
                      ),
                      child: TextField(
                        controller: keystorePasswordController,
                        maxLength: 20,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.lightBlue,
                            ),
                          ),
                          hintText: 'keystore password',
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ],
    );
    return ProgressHUD(
      child: Scaffold(
        resizeToAvoidBottomPadding: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text('Import Wallet'),
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  child: RaisedButton(
                    color:
                        currentPage == 0 ? Colors.lightBlueAccent : Colors.grey,
                    textColor: Colors.white,
                    child: Text('Mnemonic'),
                    onPressed: () {
                      pageController.jumpTo(0);
                    },
                  ),
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 50,
                ),
                Container(
                  child: RaisedButton(
                    color:
                        currentPage == 1 ? Colors.lightBlueAccent : Colors.grey,
                    textColor: Colors.white,
                    child: Text('Keystore'),
                    onPressed: () {
                      setState(() {
                        pageController.jumpToPage(1);
                      });
                    },
                  ),
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 50,
                ),
              ],
            ),
            Container(
              height: 310,
              width: MediaQuery.of(context).size.width,
              child: pageView,
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    height: 50,
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: RaisedButton(
                      color: Colors.blue,
                      onPressed: () async {
                        FocusScope.of(context).requestFocus(FocusNode());
                        setState(() {
                          loading = true;
                        });
                        switch (currentPage) {
                          case 0:
                            String mnemonic = mnemonicController.text;
                            if (mnemonic.isEmpty) {
                              setState(() {
                                loading = false;
                              });
                              return alert(context, Text('Warnning'),
                                  "Mnemonic can't be empty");
                            }
                            List<String> words =
                                await Mnemonic.populateWordList();
                            List<String> mnemonics = mnemonic.split(' ');
                            for (String m in mnemonics) {
                              if (!words.contains(m)) {
                                setState(() {
                                  loading = false;
                                });
                                return alert(context, Text('Warnning'),
                                    "Invalid mnemonic phase");
                              }
                            }
                            String walletName =
                                mnemonicWalletNameController.text;
                            if (walletName.isEmpty) {
                              setState(() {
                                loading = false;
                              });
                              return alert(context, Text('Warnning'),
                                  "Wallet name can't be empty");
                            }
                            WalletEntity walletEntity =
                                await WalletStorage.read(walletName);
                            if (walletEntity != null) {
                              setState(() {
                                loading = false;
                              });
                              return alert(context, Text('Warnning'),
                                  "This wallet name has been already existed");
                            }
                            String password = mnemonicPasswordController.text;
                            if (password.isEmpty) {
                              setState(() {
                                loading = false;
                              });
                              return alert(context, Text('Warnning'),
                                  "Password can't be empty");
                            }
                            KeyStore keystore = await compute(
                              decryptMnemonic,
                              MnemonicDecriptions(
                                  mnemonic: mnemonic, password: password),
                            );
                            WalletEntity existed =
                                await walletExisted(keystore.address);
                            if (existed != null) {
                              setState(() {
                                loading = false;
                              });
                              return customAlert(
                                context,
                                title: Text('Warnning'),
                                content: Text(
                                    'This address has been already existed,would you like to cover it?'),
                                confirmAction: () async {
                                  await WalletStorage.delete(existed.name);
                                  await WalletStorage.write(
                                    walletEntity: WalletEntity(
                                      keystore: keystore,
                                      name: walletName,
                                    ),
                                    isMainWallet: true,
                                  );
                                  Navigator.popUntil(
                                    context,
                                    ModalRoute.withName(
                                        ManageWallets.routeName),
                                  );
                                },
                                cancelAction: () async {
                                  Navigator.pop(context);
                                },
                              );
                            }
                            await WalletStorage.write(
                              walletEntity: WalletEntity(
                                name: walletName,
                                keystore: keystore,
                              ),
                              isMainWallet: true,
                            );
                            setState(() {
                              loading = false;
                            });
                            Navigator.pop(context);
                            break;
                          case 1:
                            String keystoreString = keystoreController.text;
                            if (keystoreString.isEmpty) {
                              setState(() {
                                loading = false;
                              });
                              return alert(context, Text('Warnning'),
                                  "Keystore can't be empty");
                            }
                            String password = keystorePasswordController.text;
                            String walletName =
                                keystoreWalletNameController.text;
                            if (walletName.isEmpty) {
                              setState(() {
                                loading = false;
                              });
                              return alert(context, Text('Warnning'),
                                  "Wallet name can't be empty");
                            }
                            WalletEntity walletEntity =
                                await WalletStorage.read(walletName);
                            if (walletEntity != null) {
                              setState(() {
                                loading = false;
                              });
                              return alert(context, Text('Warnning'),
                                  "This wallet name has been already existed");
                            }
                            KeyStore keystore;
                            try {
                              var keystoreJson = json.decode(keystoreString);
                              keystore = KeyStore.fromJSON(keystoreJson);
                            } catch (err) {
                              setState(() {
                                loading = false;
                              });
                              return alert(context, Text('Warnning'),
                                  "keystore is invalid");
                            }
                            try {
                              Uint8List privateKey = await compute(
                                decrypt,
                                Decriptions(
                                    keystore: keystore, password: password),
                              );
                              Uint8List publicKey =
                                  privateKeyBytesToPublic(privateKey);
                              Uint8List addr = publicKeyToAddress(publicKey);
                              WalletEntity existed =
                                  await walletExisted(bytesToHex(addr));
                              if (existed != null) {
                                setState(() {
                                  loading = false;
                                });
                                return customAlert(
                                  context,
                                  title: Text('Warnning'),
                                  content: Text(
                                      'this address has been already existed,would you like to cover it?'),
                                  confirmAction: () async {
                                    KeyStore keyS = await KeyStore.encrypt(
                                        bytesToHex(privateKey), password);
                                    await WalletStorage.delete(existed.name);
                                    await WalletStorage.write(
                                      walletEntity: WalletEntity(
                                        keystore: keyS,
                                        name: walletName,
                                      ),
                                      isMainWallet: true,
                                    );
                                    Navigator.popUntil(
                                      context,
                                      ModalRoute.withName(
                                          ManageWallets.routeName),
                                    );
                                  },
                                  cancelAction: () async {
                                    Navigator.pop(context);
                                  },
                                );
                              }
                            } catch (err) {
                              setState(() {
                                loading = false;
                              });
                              return alert(context, Text('Warnning'),
                                  "password is invalid");
                            }
                            await WalletStorage.write(
                                walletEntity: WalletEntity(
                                  name: walletName,
                                  keystore: keystore,
                                ),
                                isMainWallet: true);
                            setState(() {
                              loading = false;
                            });
                            Navigator.popUntil(context,
                                ModalRoute.withName(ManageWallets.routeName));
                            break;
                        }
                      },
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
      isLoading: loading,
    );
  }
}
