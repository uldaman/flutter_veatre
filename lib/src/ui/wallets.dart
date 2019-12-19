import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/api/accountAPI.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/ui/walletCard.dart';
import 'package:veatre/src/models/account.dart';

class Wallets extends StatefulWidget {
  @override
  WalletsState createState() => WalletsState();
}

class WalletsState extends State<Wallets> {
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
    if (mounted) {
      setState(() {
        _walletEntities = walletEntities();
        _accounts = accounts();
      });
    }
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
        title: Text('Wallets'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.only(top: 15),
        itemBuilder: buildWalletCard,
        itemCount: _walletEntities.length,
        physics: ClampingScrollPhysics(),
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
      onSelected: () async {
        Navigator.of(context).pop(walletEntity);
      },
    );
  }
}
