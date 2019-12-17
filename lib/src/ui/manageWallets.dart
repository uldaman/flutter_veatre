import 'dart:async';
import 'dart:core';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/api/accountAPI.dart';
import 'package:veatre/src/ui/walletCard.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/ui/addressDetail.dart';
import 'package:veatre/src/ui/createOrImportWallet.dart';
import 'package:veatre/src/ui/walletInfo.dart';

Map<Network, List<WalletEntity>> _walletEntities = {
  Network.MainNet: [],
  Network.TestNet: [],
};
//_accounts's length should be equal to _walletEntities
Map<Network, Map<String, Account>> _accounts = {
  Network.MainNet: {},
  Network.TestNet: {},
};

List<WalletEntity> walletEntities({Network network}) {
  return _walletEntities[network ?? Globals.network];
}

Map<String, Account> accounts({Network network}) {
  return Map.from(_accounts[network ?? Globals.network]);
}

Future<void> syncWallets({Network network}) async {
  network = network ?? Globals.network;
  List<WalletEntity> walletEntities =
      await WalletStorage.readAll(network: network);
  _walletEntities[network] = List.from(walletEntities);
  Map<String, Account> copy = Map.from(_accounts[network]);
  for (String addr in copy.keys) {
    final existedWalletEntity =
        walletEntities.firstWhere((w) => w.address == addr, orElse: () => null);
    if (existedWalletEntity == null) {
      _accounts[network].remove(addr);
    }
  }
  for (WalletEntity entity in walletEntities) {
    String address = entity.address;
    if (!_accounts[network].containsKey(address)) {
      _accounts[network][address] = null;
    }
  }
}

void updateAccount(String address, Account account, {Network network}) {
  _accounts[network ?? Globals.network][address] = account;
}

class ManageWallets extends StatefulWidget {
  static final routeName = '/wallets';

  @override
  ManageWalletsState createState() => ManageWalletsState();
}

class ManageWalletsState extends State<ManageWallets> {
  List<WalletEntity> _walletEntities;
  Map<String, Account> _accounts;

  @override
  void initState() {
    _walletEntities = walletEntities();
    _accounts = accounts();
    _load();
    Globals.addBlockHeadHandler(_load);
    super.initState();
  }

  Future<void> _load() async {
    await syncWallets();
    setState(() {
      _walletEntities = walletEntities();
      _accounts = accounts();
    });
  }

  @override
  void dispose() {
    Globals.removeBlockHeadHandler(_load);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: FlatButton(
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          padding: EdgeInsets.all(0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Close',
            ),
          ),
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        title: Text('Wallets'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.add,
              size: 30,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                new MaterialPageRoute(
                  builder: (context) => new CreateOrImportWallet(
                    fromRouteName: ManageWallets.routeName,
                  ),
                ),
              );
              await _load();
            },
          )
        ],
      ),
      body: SafeArea(
        child: _walletEntities.length > 0
            ? ListView.builder(
                padding: EdgeInsets.only(top: 15),
                physics: ClampingScrollPhysics(),
                itemBuilder: buildWalletCard,
                itemCount: _walletEntities.length,
              )
            : Center(
                child: SizedBox(
                  height: 200,
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Add your first wallet',
                        style: TextStyle(
                          fontSize: 22,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 20, left: 40, right: 40),
                        child: Text(
                          "Wallet is a universal identity on blockchain,create one to explore.",
                          style: TextStyle(
                            color: Theme.of(context)
                                .primaryTextTheme
                                .display2
                                .color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget buildWalletCard(BuildContext context, int index) {
    WalletEntity walletEntity = _walletEntities[index];
    Account account = _accounts[walletEntity.address];
    return WalletCard(
      context,
      walletEntity,
      key: ValueKey(walletEntity.address),
      initialAccount: account,
      getAccount: () async {
        account = await AccountAPI.get(walletEntity.address);
        if (account != null) {
          updateAccount(walletEntity.address, account);
        }
        return account;
      },
      onQrcodeSelected: () async {
        await showGeneralDialog(
          context: context,
          transitionDuration: Duration(milliseconds: 300),
          barrierDismissible: false,
          pageBuilder: (context, a, b) {
            return AddressDetail(
              walletEntity: walletEntity,
            );
          },
        );
      },
      onSearchSelected: () async {
        final url =
            "https://insight.vecha.in/#/${Globals.network == Network.MainNet ? 'main' : 'test'}/accounts/0x${walletEntity.address}";
        Navigator.of(context).pop(url);
      },
      onSelected: () async {
        final result = await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (BuildContext context, Animation animation,
                Animation secondaryAnimation) {
              return FadeTransition(
                opacity: animation,
                child: WalletInfo(
                  walletEntity: walletEntity,
                  account: account,
                ),
              );
            },
          ),
        );
        if (result != null) {
          Navigator.of(context).pop(result);
        } else {
          await _load();
        }
      },
    );
  }
}
