import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:veatre/src/models/certificate.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/models/keyStore.dart';
import 'package:veatre/src/api/accountAPI.dart';
import 'package:veatre/src/ui/wallets.dart';
import 'package:veatre/src/storage/storage.dart';

class SignCertificateDialog extends StatefulWidget {
  final SigningCertMessage certMessage;
  final SigningCertOptions options;

  SignCertificateDialog({this.certMessage, this.options});

  @override
  SignCertificateDialogState createState() => SignCertificateDialogState();
}

class SignCertificateDialogState extends State<SignCertificateDialog> {
  bool loading = true;
  Wallet wallet;

  @override
  void initState() {
    super.initState();
    void Function(WalletEntity walletEntity) setWallet =
        (WalletEntity walletEntity) async {
      Account acc = await AccountAPI.get(walletEntity.keystore.address);
      setState(() {
        this.wallet = Wallet(
          account: acc,
          keystore: walletEntity.keystore,
          name: walletEntity.name,
        );
      });
      setState(() {
        this.loading = false;
      });
    };

    getWalletEntity(widget.options.signer).then((walletEntity) {
      setWallet(walletEntity);
    });
    // Certificate c = Certificate(
    //   domain: 'domain',
    //   timestamp: 10,
    //   purpose: 'purpose',
    //   payload: Payload(content: 'content', type: 'type'),
    // );
    // print('c.unserialized ${c.unserialized}');
    // compute(
    //   decrypt,
    //   Decriptions(keystore: wallet.keystore, password: 'a'),
    // ).then((privateKey) {
    //   c.sign(privateKey);
    //   print('encoded ${c.encoded}');
    //   print('veify ${c.verify()}');
    // });
  }

  Future<WalletEntity> getWalletEntity(String signer) async {
    if (signer != null) {
      List<WalletEntity> walletEntities = await WalletStorage.readAll();
      for (WalletEntity walletEntity in walletEntities) {
        if ('0x' + walletEntity.keystore.address == signer) {
          return walletEntity;
        }
      }
    }
    WalletEntity mianWalletEntity = await WalletStorage.getMainWallet();
    if (mianWalletEntity != null) {
      return mianWalletEntity;
    }
    List<WalletEntity> walletEntities = await WalletStorage.readAll();
    return walletEntities[0];
  }

  showMenu() async {
    final Wallet selectedWallet = await Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new Wallets()),
    );
    if (selectedWallet != null) {
      setState(() {
        loading = true;
        this.wallet = selectedWallet;
      });
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Sign Certificate'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            size: 25,
          ),
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.menu,
              size: 25,
              color: Colors.blue,
            ),
            onPressed: () async {
              await showMenu();
            },
          )
        ],
      ),
    );
  }
}
