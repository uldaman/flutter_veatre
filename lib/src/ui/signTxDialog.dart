import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/src/api/accountAPI.dart';
import 'package:veatre/src/api/blockAPI.dart';
import 'package:veatre/src/api/transactionAPI.dart';
import 'package:veatre/src/models/account.dart';
import 'package:bip_key_derivation/bip_key_derivation.dart';
import 'package:veatre/src/models/block.dart';
import 'package:veatre/src/models/transaction.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/storage/activitiyStorage.dart';
import 'package:veatre/src/ui/progressHUD.dart';
import 'package:veatre/src/ui/alert.dart';
import 'package:veatre/src/ui/wallets.dart';
import 'package:web3dart/contracts.dart';
import 'package:veatre/src/utils/common.dart';

class SignTxDialog extends StatefulWidget {
  final List<SigningTxMessage> txMessages;
  final SigningTxOptions options;

  SignTxDialog({this.txMessages, this.options});

  @override
  SignTxDialogState createState() => SignTxDialogState();
}

class SignTxDialogState extends State<SignTxDialog> {
  double priority = 0;
  Wallet wallet;

  String vmError = '';
  bool isInsufficient = false;
  int totalGas = 0;
  BigInt spendValue = BigInt.from(0);
  BigInt estimatedFee = BigInt.from(0);
  bool loading = true;
  TextEditingController passwordController = TextEditingController();

  final txGas = 5000;
  final clauseGas = 16000;

  @override
  void initState() {
    super.initState();
    updateSpendValue();
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
      await estimateGas(wallet.keystore.address);
      setState(() {
        this.loading = false;
      });
    };
    getWalletEntity(widget.options.signer).then((walletEntity) {
      setWallet(walletEntity);
    });
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

  updateSpendValue() {
    BigInt value = BigInt.from(0);
    for (SigningTxMessage txMsg in widget.txMessages) {
      value += txMsg.toClause().value;
    }
    setState(() {
      this.spendValue = value;
    });
  }

  estimateGas(String addr) async {
    int gas = 0;
    gas += txGas;
    List<CallResult> results = await callTx(addr, widget.options.gas);
    bool hasVmError = false;
    for (CallResult result in results) {
      gas += clauseGas;
      gas += (result.gasUsed.toDouble() * 1.2).toInt();
      if (result.reverted) {
        hasVmError = true;
        Uint8List data = hexToBytes(result.data);
        String vmErr = '''Transaction may fail/revert
VM error: ${result.vmError}''';
        if (data.length > 4 + 32) {
          DecodingResult<String> err = StringType().decode(data.buffer, 4 + 32);
          vmErr += '''
          ${err.data}''';
        }
        setState(() {
          this.vmError = vmErr;
        });
        break;
      }
    }
    if (!hasVmError) {
      setState(() {
        this.vmError = '';
      });
    }
    setState(() {
      this.totalGas = widget.options.gas ?? gas;
    });
    BigInt fee = estimateFee();
    setState(() {
      this.estimatedFee = fee;
    });
    if (this.wallet.account.energy < fee) {
      setState(() {
        this.isInsufficient = true;
      });
    } else {
      setState(() {
        this.isInsufficient = false;
      });
    }
  }

  showWallets() async {
    final Wallet selectedWallet = await Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new Wallets()),
    );
    if (selectedWallet != null) {
      setState(() {
        loading = true;
        this.wallet = selectedWallet;
      });
      await estimateGas(selectedWallet.keystore.address);
      setState(() {
        loading = false;
      });
    }
  }

  BigInt estimateFee() {
    return initialBaseGasPrice *
        BigInt.from((1 + priority) * 1e10) *
        BigInt.from(totalGas) ~/
        BigInt.from(1e10);
  }

  Future<List<CallResult>> callTx(String addr, int gas) async {
    return AccountAPI.call(
      widget.txMessages,
      caller: addr,
      gas: gas,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
      child: Scaffold(
        resizeToAvoidBottomPadding: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text('Sign Transaction'),
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
                await showWallets();
              },
            )
          ],
        ),
        body: Column(
          children: <Widget>[
            isInsufficient
                ? Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          color: Colors.orangeAccent,
                          padding: EdgeInsets.all(10),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.error,
                                color: Colors.limeAccent,
                                size: 18,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 5),
                                child: Text(
                                  "Insufficient energy",
                                  textAlign: TextAlign.center,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(),
            vmError != ''
                ? Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          color: Colors.orangeAccent,
                          padding: EdgeInsets.all(10),
                          child: Row(
                            children: <Widget>[
                              Container(
                                child: Icon(
                                  Icons.error,
                                  color: Colors.limeAccent,
                                  size: 18,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 5),
                                child: Text(
                                  vmError,
                                  textAlign: TextAlign.left,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(),
            GestureDetector(
              child: Container(
                child: Card(
                  margin: EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: 85,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF81269D),
                              const Color(0xFFEE112D)
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Container(
                              width: MediaQuery.of(context).size.width,
                              child: Container(
                                padding: EdgeInsets.all(15),
                                child: Text(
                                  wallet == null ? '' : wallet.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.only(left: 15, right: 15),
                              width: MediaQuery.of(context).size.width,
                              child: Text(
                                wallet == null
                                    ? ''
                                    : '0x' + wallet.keystore.address,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text(wallet == null
                                ? '0'
                                : wallet.account.formatBalance()),
                            Container(
                              margin: EdgeInsets.only(left: 5, right: 14),
                              child: Text(
                                'VET',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text(wallet == null
                                ? '0'
                                : wallet.account.formatEnergy()),
                            Container(
                              margin: EdgeInsets.only(left: 5, right: 5),
                              child: Text(
                                'VTHO',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                width: MediaQuery.of(context).size.width,
                height: 170,
              ),
              onTap: () async {
                await showWallets();
              },
            ),
            Container(
              margin: EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  Text(
                    'Spend value',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          "${fixed2Value(spendValue)}",
                          style: TextStyle(color: Colors.black),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 5, right: 9),
                          child: Text(
                            'VET',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              width: MediaQuery.of(context).size.width,
            ),
            Container(
              margin: EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  Text(
                    'Estimated fee',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          "${fixed2Value(estimatedFee)}",
                          style: TextStyle(color: Colors.black),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 5),
                          child: Text(
                            'VTHO',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              width: MediaQuery.of(context).size.width,
            ),
            Container(
              margin: EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  Text(
                    'Accelaration',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Slider(
                          activeColor: Colors.blueAccent,
                          onChanged: (value) async {
                            setState(() {
                              this.priority = value;
                            });
                            setState(() {
                              this.estimatedFee = estimateFee();
                            });
                          },
                          value: priority,
                        )
                      ],
                    ),
                  )
                ],
              ),
              width: MediaQuery.of(context).size.width,
            ),
            widget.options.comment != null
                ? Container(
                    margin: EdgeInsets.all(10),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text('${widget.options.comment}'),
                        ),
                      ],
                    ),
                    width: MediaQuery.of(context).size.width,
                  )
                : Row(),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                      itemBuilder: buildClause,
                      itemCount: widget.txMessages.length,
                      physics: ClampingScrollPhysics(),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          height: 50,
                          child: FlatButton(
                            color: Colors.blue,
                            child: Text(
                              'Confirm',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () async {
                              await customAlert(context,
                                  title: Text('Sign transaction'),
                                  content: TextField(
                                    controller: passwordController,
                                    maxLength: 20,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: 'Input your password',
                                    ),
                                  ), confirmAction: () async {
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
                                String password = passwordController.text;
                                if (password.isEmpty) {
                                  return alert(
                                    context,
                                    Text('Warnning'),
                                    "Password can't be empty",
                                  );
                                }
                                Navigator.pop(context);
                                setState(() {
                                  loading = true;
                                });
                                Uint8List privateKey;
                                try {
                                  privateKey = await BipKeyDerivation
                                      .decryptedByKeystore(
                                    wallet.keystore,
                                    password,
                                  );
                                } catch (err) {
                                  setState(() {
                                    loading = false;
                                  });
                                  return alert(
                                    context,
                                    Text('Warnning'),
                                    "Password Invalid",
                                  );
                                }
                                Block block;
                                try {
                                  block = await BlockAPI.best();
                                } catch (err) {
                                  setState(() {
                                    loading = false;
                                  });
                                  return alert(context, Text("Warnning"),
                                      "network error");
                                }
                                int nonce = Random(DateTime.now().millisecond)
                                    .nextInt(1 << 32);
                                List<Clause> clauses = [];
                                for (SigningTxMessage txMsg
                                    in widget.txMessages) {
                                  clauses.add(txMsg.toClause());
                                }
                                Transaction tx = Transaction(
                                  blockRef: BlockRef(number32: block.number),
                                  expiration: 20,
                                  chainTag: testNetwork,
                                  clauses: clauses,
                                  gasPriceCoef: (255 * priority).toInt(),
                                  gas: totalGas,
                                  dependsOn:
                                      widget.options.dependsOn ?? Uint8List(0),
                                  nonce: nonce,
                                );
                                tx.sign(privateKey);
                                try {
                                  await WalletStorage.setMainWallet(
                                    WalletEntity(
                                      keystore: wallet.keystore,
                                      name: wallet.name,
                                    ),
                                  );
                                  Map<String, dynamic> result =
                                      await TransactionAPI.send(tx.serialized);
                                  int timestamp = new DateTime.now()
                                          .millisecondsSinceEpoch ~/
                                      1000;
                                  String comment = 'Empty transaction';
                                  if (widget.options == null) {
                                    if (widget.txMessages.length > 1) {
                                      comment = 'Perform a batch of clauses';
                                    } else if (widget.txMessages.length == 1) {
                                      SigningTxMessage msg =
                                          widget.txMessages.first;
                                      comment =
                                          msg.comment ?? msg.data.length > 2
                                              ? 'Make a contract call'
                                              : 'Transfer VET';
                                    }
                                  }
                                  await ActivityStorage.insert(
                                    Activity(
                                      hash: result['id'],
                                      content: json.encode({
                                        'amount': fixed2Value(spendValue),
                                        'fee': fixed2Value(estimatedFee),
                                      }),
                                      link: widget.options.link,
                                      walletName: wallet.name,
                                      type: ActivityType.Transaction,
                                      comment: comment,
                                      timestamp: timestamp,
                                      status: ActivityStatus.Pending,
                                    ),
                                  );
                                  Navigator.of(context).pop(
                                    SigningTxResponse(
                                      txid: result['id'],
                                      signer: '0x' + wallet.keystore.address,
                                    ),
                                  );
                                } catch (err) {
                                  return alert(context, Text("Error"),
                                      "Send transaction failed");
                                } finally {
                                  setState(() {
                                    loading = false;
                                  });
                                }
                              }, cancelAction: () async {
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
                                Navigator.pop(context);
                              });
                            },
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
      isLoading: loading,
    );
  }

  Widget buildClause(BuildContext context, int index) {
    SigningTxMessage txMessage = widget.txMessages[index];

    Widget clauseCard = Container(
      child: Card(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 80,
                  margin: EdgeInsets.only(top: 15, left: 10),
                  child: Text(
                    'To',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 15, left: 5, right: 10),
                    child: Text(txMessage.to),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 15, left: 10),
                  width: 80,
                  child: Text(
                    'Value',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 15, left: 5, right: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text("${fixed2Value(BigInt.parse(txMessage.value))}"),
                        Container(
                          margin: EdgeInsets.only(left: 5),
                          child: Text(
                            'VET',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 15, left: 10),
                  width: 80,
                  child: Text(
                    'Inpu data',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 15, left: 5, right: 10),
                    child: Text(txMessage.data),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Container(
                  width: 80,
                  margin: EdgeInsets.only(top: 15, left: 10, bottom: 15),
                  child: Text(
                    'Comment',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                        top: 15, left: 5, right: 10, bottom: 15),
                    child: Text(txMessage.comment),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return clauseCard;
  }
}
