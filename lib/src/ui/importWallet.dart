import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bip_key_derivation/keystore.dart';
import 'package:bip_key_derivation/bip_key_derivation.dart';
import 'package:veatre/src/storage/networkStorage.dart';
import 'package:veatre/src/ui/alert.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/ui/progressHUD.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/utils/common.dart';

class ImportWallet extends StatefulWidget {
  static final routeName = '/wallets/import';

  @override
  ImportWalletState createState() => ImportWalletState();
}

class ImportWalletState extends State<ImportWallet> {
  int currentPage = 0;
  bool loading = false;
  Network network;
  TextEditingController mnemonicController = TextEditingController();
  TextEditingController mnemonicWalletNameController = TextEditingController();
  TextEditingController mnemonicPasswordController = TextEditingController();
  TextEditingController keystoreController = TextEditingController();
  TextEditingController keystoreWalletNameController = TextEditingController();
  TextEditingController keystorePasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    NetworkStorage.network.then((network) {
      this.network = network;
    });
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
                  child: Padding(
                    padding: EdgeInsets.all(5),
                    child: TextFormField(
                      controller: mnemonicController,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(10),
                        hintText:
                            'Input your mnemonic phase which is splited by whitespace',
                      ),
                      maxLines: 30,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.body1.color,
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
                    child: TextField(
                      controller: mnemonicWalletNameController,
                      maxLength: 20,
                      decoration: InputDecoration(
                        hintText: 'Wallet Name',
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.body1.color,
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
                    child: TextField(
                      controller: mnemonicPasswordController,
                      maxLength: 20,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'New Password',
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.body1.color,
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
                  child: Padding(
                    padding: EdgeInsets.all(5),
                    child: TextFormField(
                      controller: keystoreController,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(10),
                        hintText: 'Input your keystore',
                      ),
                      maxLines: 30,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.body1.color,
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
                    child: TextField(
                      controller: keystoreWalletNameController,
                      maxLength: 20,
                      decoration: InputDecoration(
                        hintText: 'Wallet Name',
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.body1.color,
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
                    child: TextField(
                      controller: keystorePasswordController,
                      maxLength: 20,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Keystore Password',
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.body1.color,
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
        backgroundColor: Theme.of(context).primaryColor,
        resizeToAvoidBottomPadding: false,
        appBar: AppBar(
          title: Text('Import Wallet'),
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: SizedBox(
                    child: Card(
                      clipBehavior: Clip.hardEdge,
                      margin: EdgeInsets.all(0),
                      child: FlatButton(
                        color: currentPage == 0 ? Colors.red : Colors.grey[200],
                        textColor:
                            currentPage == 0 ? Colors.white : Colors.blue,
                        child: Text('Mnemonic'),
                        onPressed: () {
                          pageController.animateToPage(
                            0,
                            duration: Duration(milliseconds: 200),
                            curve: Curves.easeIn,
                          );
                        },
                      ),
                    ),
                    width: MediaQuery.of(context).size.width * 0.5 - 20,
                    height: 50,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: SizedBox(
                    child: Card(
                      clipBehavior: Clip.hardEdge,
                      margin: EdgeInsets.all(0),
                      child: FlatButton(
                        color: currentPage == 1 ? Colors.red : Colors.grey[200],
                        textColor:
                            currentPage == 1 ? Colors.white : Colors.blue,
                        child: Text('Keystore'),
                        onPressed: () {
                          pageController.animateToPage(
                            1,
                            duration: Duration(milliseconds: 200),
                            curve: Curves.easeIn,
                          );
                        },
                      ),
                    ),
                    width: MediaQuery.of(context).size.width * 0.5 - 20,
                    height: 50,
                  ),
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
                            bool isValid =
                                await BipKeyDerivation.isValidMnemonic(
                                    mnemonic);
                            if (!isValid) {
                              setState(() {
                                loading = false;
                              });
                              return alert(context, Text('Warnning'),
                                  "Invalid mnemonic phase");
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
                                await WalletStorage.read(
                              walletName,
                              network,
                            );
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
                            if (bool.fromEnvironment('dart.vm.product') &&
                                password.length < 6) {
                              return alert(context, Text("Warnning"),
                                  "Password must be 6 characters at least!");
                            }
                            Uint8List privateKey =
                                await BipKeyDerivation.decryptedByMnemonic(
                                    mnemonic, defaultDerivationPath);
                            Uint8List publicKey =
                                await BipKeyDerivation.privateToPublic(
                                    privateKey);
                            Uint8List address =
                                await BipKeyDerivation.publicToAddress(
                                    publicKey);
                            KeyStore keystore = await BipKeyDerivation.encrypt(
                                privateKey, password);
                            keystore.address = bytesToHex(address);
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
                                  await WalletStorage.delete(
                                    existed.name,
                                    network,
                                  );
                                  await WalletStorage.write(
                                    walletEntity: WalletEntity(
                                      keystore: keystore,
                                      name: walletName,
                                    ),
                                    network: network,
                                  );
                                  Navigator.popUntil(
                                    context,
                                    ModalRoute.withName(
                                        ManageWallets.routeName),
                                  );
                                },
                              );
                            }
                            await WalletStorage.write(
                              walletEntity: WalletEntity(
                                name: walletName,
                                keystore: keystore,
                              ),
                              network: network,
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
                                await WalletStorage.read(
                              walletName,
                              network,
                            );
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
                                  "Keystore is invalid");
                            }
                            try {
                              await BipKeyDerivation.decryptedByKeystore(
                                  keystore, password);
                            } catch (err) {
                              return alert(
                                  context, Text('Warnning'), err.toString());
                            }
                            try {
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
                                    await WalletStorage.delete(
                                      existed.name,
                                      network,
                                    );
                                    await WalletStorage.write(
                                      walletEntity: WalletEntity(
                                        keystore: keystore,
                                        name: walletName,
                                      ),
                                      network: network,
                                    );
                                    Navigator.popUntil(
                                      context,
                                      ModalRoute.withName(
                                          ManageWallets.routeName),
                                    );
                                  },
                                );
                              }
                            } catch (err) {
                              setState(() {
                                loading = false;
                              });
                              return alert(context, Text('Warnning'),
                                  "Password is invalid");
                            }
                            await WalletStorage.write(
                              walletEntity: WalletEntity(
                                name: walletName,
                                keystore: keystore,
                              ),
                              network: network,
                            );
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

  Future<WalletEntity> walletExisted(String address) async {
    List<WalletEntity> walletEntities = await WalletStorage.readAll(network);
    for (WalletEntity walletEntity in walletEntities) {
      if (walletEntity.keystore.address == address) {
        return walletEntity;
      }
    }
    return null;
  }
}
