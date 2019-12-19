import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/ui/activityCard.dart';
import 'package:veatre/src/ui/walletCard.dart';
import 'package:veatre/src/api/accountAPI.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/storage/activitiyStorage.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/ui/walletOperation.dart';

class WalletInfo extends StatefulWidget {
  final WalletEntity walletEntity;
  final Account account;

  WalletInfo({
    this.walletEntity,
    this.account,
  });

  @override
  WalletInfoState createState() => WalletInfoState();
}

class WalletInfoState extends State<WalletInfo> {
  List<Activity> activities = [];
  WalletEntity walletEntity;
  Account initialAccount;
  @override
  void initState() {
    walletEntity = widget.walletEntity;
    initialAccount = widget.account;
    super.initState();
    _handleHeadChanged();
    Globals.addBlockHeadHandler(_handleHeadChanged);
  }

  Future<void> updateWalletEntity() async {
    final walletEntity = await WalletStorage.read(widget.walletEntity.address);
    if (mounted && walletEntity != null) {
      setState(() {
        this.walletEntity = walletEntity;
      });
    }
  }

  void _handleHeadChanged() async {
    if (Globals.blockHeadForNetwork.network == Globals.network) {
      await updateWalletEntity();
      await loadActivities();
    }
  }

  Future<void> loadActivities() async {
    try {
      List<Activity> activities =
          await ActivityStorage.query(widget.walletEntity.address);
      if (mounted) {
        setState(() {
          this.activities = activities;
        });
      }
    } catch (e) {
      print("loadActivities error: $e");
    }
  }

  @override
  void dispose() {
    Globals.removeBlockHeadHandler(_handleHeadChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Details'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              MaterialCommunityIcons.dots_vertical,
            ),
            iconSize: 20,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => WalletOperation(
                    walletEntity: walletEntity,
                  ),
                  settings: RouteSettings(name: '/wallet/operation'),
                ),
              );
              await updateWalletEntity();
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 1),
            child: buildWalletCard(context, walletEntity),
          ),
          Padding(
            padding: EdgeInsets.only(top: 15, left: 15, right: 15),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Activities',
                style: TextStyle(
                  color: Theme.of(context).primaryTextTheme.subtitle.color,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          Expanded(
            child: activities.length > 0
                ? ListView.builder(
                    padding: EdgeInsets.only(bottom: 15, top: 10),
                    itemBuilder: buildActivity,
                    itemCount: activities.length,
                    physics: ClampingScrollPhysics(),
                  )
                : Center(
                    child: SizedBox(
                      height: 200,
                      child: Column(
                        children: <Widget>[
                          Text(
                            'No Activity',
                            style: TextStyle(
                              fontSize: 22,
                            ),
                          ),
                          Padding(
                            padding:
                                EdgeInsets.only(top: 20, left: 40, right: 40),
                            child: Text(
                              "Transaction and Certificate that you've signed will appear here",
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
        ],
      ),
    );
  }

  Widget buildWalletCard(BuildContext context, WalletEntity walletEntity) {
    return WalletCard(
      context,
      walletEntity,
      hasHorizontalMargin: false,
      elevation: 1,
      initialAccount: initialAccount,
      getAccount: () => AccountAPI.get(walletEntity.address),
    );
  }

  Widget buildActivity(BuildContext context, int index) {
    Activity activity = activities[index];
    return ActivityCard(activity);
  }
}
