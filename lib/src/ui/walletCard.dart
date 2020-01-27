import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/ui/picasso.dart';
import 'package:veatre/src/utils/common.dart';

class WalletCard extends StatelessWidget {
  const WalletCard(
    this.context,
    this.walletEntity, {
    Key key,
    this.onSelected,
    this.onQrcodeSelected,
    this.onSearchSelected,
    this.initialAccount,
    this.hasHorizontalMargin = true,
    this.elevation = 2.0,
    @required this.getAccount,
  }) : super(key: key);

  final BuildContext context;
  final Future<void> Function() onSelected;
  final Future<void> Function() onQrcodeSelected;
  final Future<void> Function() onSearchSelected;
  final Future<Account> Function() getAccount;
  final WalletEntity walletEntity;
  final Account initialAccount;
  final bool hasHorizontalMargin;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Hero(
        tag: '0x${walletEntity.address}',
        child: Card(
          elevation: elevation,
          margin: EdgeInsets.only(
            left: hasHorizontalMargin ? 15 : 0,
            right: hasHorizontalMargin ? 15 : 0,
            bottom: 15,
          ),
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
                                fontSize: 13,
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
                    return balance(shot.data, initialAccount);
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

  Widget value(
    Account account,
    Account initialAccount, {
    bool isBalance = true,
  }) {
    return DefaultTextStyle(
      child: initialAccount == null && account != null
          ? _ValueChange(
              key: ValueKey(
                isBalance ? account.formatBalance : account.formatEnergy,
              ),
              value: isBalance ? account.balance : account.energy,
            )
          : initialAccount == null
              ? Text('--')
              : account == null
                  ? Text(
                      isBalance
                          ? initialAccount.formatBalance
                          : initialAccount.formatEnergy,
                    )
                  : _ValueChange(
                      key: ValueKey(
                        isBalance
                            ? account.formatBalance
                            : account.formatEnergy,
                      ),
                      value: isBalance ? account.balance : account.energy,
                      oldValue: isBalance
                          ? initialAccount.balance
                          : initialAccount.energy,
                    ),
      style: TextStyle(
        fontSize: isBalance ? 22 : 14,
        color: Theme.of(context).primaryTextTheme.title.color,
        fontWeight: FontWeight.normal,
        decoration: TextDecoration.none,
      ),
      overflow: TextOverflow.clip,
      maxLines: 1,
    );
  }

  Widget balance(Account account, Account initialAccount) {
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              value(
                account,
                initialAccount,
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
              value(
                account,
                initialAccount,
                isBalance: false,
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
}

class _ValueChange extends StatefulWidget {
  final BigInt value;
  final BigInt oldValue;

  _ValueChange({
    Key key,
    this.value,
    this.oldValue,
  }) : super(key: key);

  _ValueChangeState createState() => _ValueChangeState();
}

class _ValueChangeState extends State<_ValueChange>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;
  BigInt value;
  BigInt oldValue;
  BigInt _diff;

  @override
  void initState() {
    super.initState();
    value = widget.value ?? BigInt.zero;
    oldValue = widget.oldValue ?? BigInt.zero;
    _diff = value - oldValue;
    controller = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    animation =
        CurvedAnimation(parent: controller, curve: Curves.linearToEaseOut)
            .drive(Tween<double>(begin: 0.0, end: 100.0));
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final bigVT = BigInt.from(animation.value.toInt());
        final currentValue = oldValue + (_diff * bigVT) ~/ BigInt.from(100);
        return Text('${formatNum(fixed2Value(currentValue))}');
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
