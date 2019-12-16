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
    if (initialAccount == null && account != null) {
      return _ValueChange(
        key: ValueKey(
          isBalance ? account.formatBalance : account.formatEnergy,
        ),
        value: isBalance ? account.balance : account.energy,
        style: TextStyle(fontSize: isBalance ? 22 : 14),
      );
    }
    return initialAccount == null
        ? Text(
            '--',
            style: TextStyle(fontSize: isBalance ? 22 : 14),
          )
        : account == null
            ? Text(
                isBalance
                    ? initialAccount.formatBalance
                    : initialAccount.formatEnergy,
                style: TextStyle(fontSize: isBalance ? 22 : 14),
              )
            : _ValueChange(
                key: ValueKey(
                  isBalance ? account.formatBalance : account.formatEnergy,
                ),
                value: isBalance ? account.balance : account.energy,
                oldValue:
                    isBalance ? initialAccount.balance : initialAccount.energy,
                style: TextStyle(fontSize: isBalance ? 22 : 14),
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

class _ValueAnimation extends AnimatedWidget {
  final BigInt oldValue;
  final BigInt value;
  final TextStyle style;
  static final _valueTween = Tween<double>(begin: 0.0, end: 1000.0);

  _ValueAnimation({
    Key key,
    Animation<double> animation,
    this.value,
    this.oldValue,
    this.style,
  }) : super(key: key, listenable: animation);

  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final vt = _valueTween.evaluate(animation);
    final diff = value - oldValue;
    final bigVT = BigInt.from(vt.toInt());
    final currentValue = oldValue + (diff * bigVT) ~/ BigInt.from(1000);
    return Text(
      '${formatNum(fixed2Value(currentValue))}',
      style: style,
    );
  }
}

class _ValueChange extends StatefulWidget {
  final BigInt value;
  final BigInt oldValue;
  final TextStyle style;

  _ValueChange({
    Key key,
    this.value,
    this.oldValue,
    this.style,
  }) : super(key: key);

  _ValueChangeState createState() => _ValueChangeState();
}

class _ValueChangeState extends State<_ValueChange>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;
  BigInt value;
  BigInt oldValue;

  @override
  void initState() {
    super.initState();
    value = widget.value ?? BigInt.zero;
    oldValue = widget.oldValue ?? BigInt.zero;
    controller = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);
    animation = CurvedAnimation(parent: controller, curve: Curves.easeIn);
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (fixed2Value(value) == fixed2Value(oldValue)) {
      return Text(
        '${formatNum(fixed2Value(value))}',
        style: widget.style,
      );
    }
    return _ValueAnimation(
      animation: animation,
      value: value,
      oldValue: oldValue,
      style: widget.style,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
