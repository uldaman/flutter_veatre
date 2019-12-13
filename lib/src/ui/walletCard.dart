import 'package:flutter/material.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/ui/picasso.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:flutter_icons/flutter_icons.dart';

class WalletCard extends StatelessWidget {
  const WalletCard(
    this.context,
    this.walletEntity, {
    Key key,
    this.onSelected,
    this.onQrcodeSelected,
    this.onSearchSelected,
    this.initialAccount,
    @required this.getAccount,
  }) : super(key: key);

  final BuildContext context;
  final Future<void> Function() onSelected;
  final Future<void> Function() onQrcodeSelected;
  final Future<void> Function() onSearchSelected;
  final Future<Account> Function() getAccount;
  final WalletEntity walletEntity;
  final Account initialAccount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Hero(
        tag: '0x${walletEntity.address}',
        child: Card(
          margin: EdgeInsets.only(left: 15, right: 15, top: 15),
          child: Container(
            margin: EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(left: 10, top: 10, right: 10),
                      child: Picasso(
                        '0x${walletEntity.address}',
                        size: 60,
                        borderRadius: 10,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                              walletEntity.name,
                              style: TextStyle(
                                fontSize: 22,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              '0x${abbreviate(walletEntity.address)}',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .display2
                                    .color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: this.onQrcodeSelected != null,
                      child: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: IconButton(
                          icon: Icon(
                            MaterialCommunityIcons.qrcode,
                            size: 30,
                          ),
                          onPressed: () async {
                            await this.onQrcodeSelected();
                          },
                        ),
                      ),
                    ),
                    Visibility(
                      visible: this.onSearchSelected != null,
                      child: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: IconButton(
                          icon: Icon(
                            MaterialCommunityIcons.file_find_outline,
                            size: 30,
                          ),
                          onPressed: () async {
                            await this.onSearchSelected();
                          },
                        ),
                      ),
                    )
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: 10,
                    left: 15,
                    right: 15,
                  ),
                  child: Divider(
                    thickness: 1,
                    height: 1,
                  ),
                ),
                FutureBuilder(
                  initialData: initialAccount,
                  future: getAccount(),
                  builder: (context, shot) {
                    Account account = shot.data;
                    return balance(
                      account?.formatBalance ?? '--',
                      account?.formatEnergy ?? '--',
                      walletEntity.address,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      onTapUp: (details) async {
        if (this.onSelected != null) await this.onSelected();
      },
    );
  }

  Widget balance(String balance, String energy, String address) {
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              valueAnimation(
                Text(
                  balance,
                  key: ValueKey("$balance"),
                  style: TextStyle(fontSize: 22),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 5, right: 22, top: 10),
                child: Text(
                  'VET',
                  style: TextStyle(
                    color: Theme.of(context).primaryTextTheme.display2.color,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              valueAnimation(
                Text(
                  energy,
                  key: ValueKey("$energy"),
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 5, right: 12, top: 2),
                child: Text(
                  'VTHO',
                  style: TextStyle(
                    color: Theme.of(context).primaryTextTheme.display2.color,
                    fontSize: 12,
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget valueAnimation(Widget child) {
    return AnimatedSwitcher(
        duration: const Duration(seconds: 1),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            child: child,
            scale: animation.drive(
              Tween(begin: 0.0, end: 1.0),
            ),
          );
        },
        child: child);
  }
}
