import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/api/accountAPI.dart';
import 'package:veatre/src/models/certificate.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/storage/activitiyStorage.dart';
import 'package:veatre/src/ui/sign_dialog/bottom_modal/summary.dart';
import 'package:veatre/src/ui/swipeButton.dart';
import 'package:veatre/src/ui/wallets.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/utils/common.dart';

class SignCertificate extends StatefulWidget {
  final SigningCertMessage certMessage;
  final SigningCertOptions options;

  SignCertificate(this.certMessage, this.options);

  @override
  SignCertificateState createState() => SignCertificateState();
}

class SignCertificateState extends State<SignCertificate>
    with SingleTickerProviderStateMixin {
  Account _account;
  WalletEntity _walletEntity;
  bool _canInteractInterface = true;
  Animation _animation;
  AnimationController _controller;
  SwipeController _swipeController = SwipeController();
  @override
  void initState() {
    init();
    super.initState();
  }

  Future<void> init() async {
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _animation = Tween(begin: 600.0, end: 54.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    final walletEntity =
        await WalletStorage.getWalletEntity(widget.options.signer);
    setState(() {
      this._walletEntity = walletEntity;
    });
    await updateAccount(walletEntity.address);
    Globals.addBlockHeadHandler(_handleHeadChanged);
  }

  Future<void> updateAccount(String address) async {
    try {
      Account account = await AccountAPI.get(_walletEntity.address);
      if (mounted) {
        setState(() {
          this._account = account;
        });
      }
    } catch (e) {
      print('updateAccount error: $e ');
    }
  }

  void _handleHeadChanged() async {
    if (Globals.blockHeadForNetwork.network == Globals.network) {
      await updateAccount(_walletEntity.address);
    }
  }

  @override
  void dispose() {
    Globals.removeBlockHeadHandler(_handleHeadChanged);
    super.dispose();
  }

  Future<void> changeWallet() async {
    final walletEntity = await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => new Wallets(),
      ),
    );
    if (walletEntity != null) {
      setState(() {
        this._walletEntity = walletEntity;
      });
      await updateAccount(walletEntity.address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.2),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Container(
          color: Theme.of(context).backgroundColor,
          padding: EdgeInsets.only(top: 8, left: 26, right: 26, bottom: 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width / 3,
                  child: Divider(
                    thickness: 4,
                    height: 4,
                  ),
                ),
              ),
              Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      children: <Widget>[
                        Text(
                          'Certificate',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 17,
                                ),
                              ),
                              onTapUp: (details) => Navigator.of(context).pop(),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Divider(
                    thickness: 1,
                    height: 1,
                  ),
                ],
              ),
              cell(
                context,
                'Wallet',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Picasso(
                          '0x${_walletEntity?.address ?? ""}',
                          size: 20,
                          borderRadius: 3,
                        ),
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              _walletEntity?.name ?? "",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Text(
                          '(0x' +
                              abbreviate('${_walletEntity?.address ?? ""}') +
                              ')',
                          style: TextStyle(
                            color: Theme.of(context)
                                .primaryTextTheme
                                .display2
                                .color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            _account?.formatBalance ?? '--',
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 5, right: 8, top: 2),
                            child: Text(
                              'VET',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .display2
                                    .color,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          _account?.formatEnergy ?? '--',
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 5, top: 2),
                          child: Text(
                            'VTHO',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .display2
                                  .color,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                showIcon: true,
                onPressed: () async {
                  if (_canInteractInterface) {
                    await changeWallet();
                  }
                },
              ),
              cell(
                context,
                'Type',
                Text(
                  widget.certMessage.purpose.toUpperCase(),
                ),
              ),
              cell(
                context,
                'Message',
                Text(
                  widget.certMessage.payload.content,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 5,
                ),
                showIcon: true,
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Summary(
                        title: 'Message',
                        content: widget.certMessage.payload.content,
                      ),
                    ),
                  );
                },
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Text(
                        'Your signature is being requested. Please review the content before you signed. Always make sure you trust the sites you interact with.',
                        style: TextStyle(
                          color:
                              Theme.of(context).primaryTextTheme.display2.color,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Container(
                        width: _animation.value,
                        child: SwipeButton(
                          swipeController: _swipeController,
                          content: Center(
                            child: Text(
                              'Slide to sign',
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(27)),
                          height: 54,
                          onStarted: () => _canInteractInterface = false,
                          onCancelled: () => _canInteractInterface = true,
                          onEnded: signCert,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> signCert() async {
    _canInteractInterface = false;
    _swipeController.valueWith(
      enabled: false,
      shouldLoading: true,
      rollBack: true,
    );
    await _controller.forward();
    try {
      Uint8List privateKey =
          await _walletEntity.decryptPrivateKey(Globals.masterPasscodes);
      final head = Globals.head();
      int timestamp = head.timestamp;
      final uri = Uri.parse(widget.options.link);
      Certificate cert = Certificate(
        certMessage: widget.certMessage,
        timestamp: timestamp,
        domain: uri?.host ?? '',
        signer: '0x' + _walletEntity.address,
      );
      cert.sign(privateKey);
      await ActivityStorage.insert(
        Activity(
          block: head.number,
          content: json.encode(cert.unserialized),
          link: widget.options.link,
          address: _walletEntity.address,
          type: ActivityType.Certificate,
          comment: 'Certification',
          timestamp: timestamp,
          network: Globals.network,
          status: ActivityStatus.Finished,
        ),
      );
      await WalletStorage.setMainWallet(_walletEntity);
      _swipeController.valueWith(
        enabled: true,
        shouldLoading: true,
        rollBack: false,
      );
      Navigator.of(context).pop(cert.response);
    } catch (err) {
      _swipeController.valueWith(
        enabled: true,
        shouldLoading: false,
        rollBack: true,
      );
      return alert(context, Text("Error"), "$err");
    }
    _canInteractInterface = true;
  }
}
