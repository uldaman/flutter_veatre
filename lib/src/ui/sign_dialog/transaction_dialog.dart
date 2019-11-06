import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:veatre/src/ui/clauses.dart';
import 'package:web3dart/contracts.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/api/accountAPI.dart';
import 'package:veatre/src/api/transactionAPI.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/models/transaction.dart';
import 'package:veatre/src/storage/activitiyStorage.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/swipeButton.dart';
import 'package:veatre/src/ui/sign_dialog/bottom_modal/bottom_modal.dart';
import 'package:veatre/src/ui/sign_dialog/bottom_modal/row_element.dart';
import 'package:veatre/src/ui/sign_dialog/bottom_modal/summary.dart';
import 'package:veatre/src/ui/sign_dialog/bottom_modal/wallet_card.dart';
import 'package:veatre/src/ui/wallets.dart';

class TransactionDialog extends StatefulWidget {
  const TransactionDialog({
    @required this.options,
    @required this.txMessages,
  });

  final SigningTxOptions options;
  final List<SigningTxMessage> txMessages;

  @override
  _TransactionState createState() => _TransactionState();
}

class _TransactionState extends State<TransactionDialog>
    with SingleTickerProviderStateMixin {
  Account _account;
  WalletEntity _entity;
  BigInt _estimatedFee;
  int _intrinsicGas;
  int _totalGas;
  List<Clause> _clauses = [];
  StreamController<String> _vmErrStreamController = StreamController<String>();

  BigInt _totalVet = BigInt.from(0);
  int _priority = 0;
  SwipeController _swipeController = SwipeController();
  AnimationController _animationController;
  Animation _animation;

  @override
  void initState() {
    _swipeController.valueWith(shouldLoading: true, enabled: false);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _animation = Tween(begin: 600.0, end: 44.0).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });

    for (SigningTxMessage txMsg in widget.txMessages) {
      _clauses.add(txMsg.toClause());
      _totalVet += txMsg.toClause().value;
    }
    _intrinsicGas = Transaction.intrinsicGas(_clauses);
    _initWalletEntity();
    Globals.addBlockHeadHandler(_handleHeadChanged);
    super.initState();
  }

  @override
  void dispose() {
    Globals.removeBlockHeadHandler(_handleHeadChanged);
    _animationController.dispose();
    _vmErrStreamController.close();
    super.dispose();
  }

  Future<void> _handleHeadChanged() async {
    if (Globals.blockHeadForNetwork.network == Globals.network) {
      await _completeByEntity(_entity);
    }
  }

  Future<void> _initWalletEntity() async {
    WalletEntity primalEntity = await WalletStorage.getWalletEntity(
      widget.options.signer,
    );
    if (primalEntity != null) {
      _swipeController.valueWith(shouldLoading: true, enabled: false);
      await _completeByEntity(primalEntity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomModal(
      title: 'Transaction',
      bottomActionButton: SizedBox(
        child: SwipeButton(
          swipeController: _swipeController,
          content: Center(
            child: Text(
              _swipeController.value.enabled
                  ? 'Slide to send transaction'
                  : 'Loading...',
              style: TextStyle(
                fontSize: 17,
                color: Colors.white,
              ),
            ),
          ),
          borderRadius: BorderRadius.all(Radius.circular(22)),
          height: 44,
          onDragEnd: () {
            _animationController.forward();
            _swipeController.valueWith(shouldLoading: true, enabled: false);
            _signTx();
          },
        ),
        width: _animation.value,
      ),
      content: Column(
        children: <Widget>[
          _buildWalletRow(),
          SizedBox(height: 16),
          Divider(thickness: 1, height: 0),
          _buildPriorityRow(),
          Divider(thickness: 1, height: 0),
          SizedBox(height: 16),
          _buildSummaryRow(),
          _buildDivider(),
          _buildClausesRow(),
          _buildDivider(),
          _buildTotalValue(),
          SizedBox(height: 8),
          _buildFee(),
          _buildDivider(),
          Spacer(),
          StreamBuilder<String>(
            stream: _vmErrStreamController.stream,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error,
                    color: Theme.of(context).errorColor,
                    size: 17,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: GestureDetector(
                      onTap: () => alert(
                        context,
                        Text('Transaction failed/reverted'),
                        '${snapshot.data}',
                      ),
                      child: Text(
                        'Transaction may fail/revert',
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).errorColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 21),
        ],
      ),
    );
  }

  void _signTx() {
    _entity.decryptPrivateKey(Globals.masterPasscodes).then((privateKey) {
      int nonce = Random(DateTime.now().millisecond).nextInt(1 << 32);
      int chainTag = Globals.network == Network.MainNet ? 0x4a : 0x27;
      final head = Globals.head();
      Transaction tx = Transaction(
        blockRef: BlockRef(number32: head.number),
        expiration: 18,
        chainTag: chainTag,
        clauses: _clauses,
        gasPriceCoef: _priority,
        gas: _totalGas,
        dependsOn: widget.options.dependsOn ?? Uint8List(0),
        nonce: nonce,
      );
      tx.sign(privateKey);
      WalletStorage.setMainWallet(_entity);
      TransactionAPI.send(tx.serialized).then((result) {
        List<Map<String, dynamic>> content = [];
        for (final clause in widget.txMessages) {
          content.add(clause.encoded);
        }
        ActivityStorage.insert(
          Activity(
            hash: result['id'],
            block: head.number,
            content: json.encode({
              'messages': content,
              'fee': _estimatedFee.toRadixString(16),
              'gas': _totalGas,
              'priority': _priority,
            }),
            link: widget.options.link,
            address: _entity.address,
            type: ActivityType.Transaction,
            comment: _makeSummary(shotSummary: true),
            timestamp: head.timestamp,
            network: Globals.network,
            status: ActivityStatus.Pending,
          ),
        );
        Navigator.of(context).pop(
          SigningTxResponse(
            txid: result['id'],
            signer: '0x' + _entity.address,
          ),
        );
      }).catchError((err) async {
        if (err.response != null) {
          await alert(
            context,
            Text('Send transaction failed'),
            '${err.response.data}',
          );
        }
        await _animationController.reverse();
        _swipeController.valueWith(
          shouldLoading: false,
          enabled: true,
          rollBack: true,
        );
      });
    });
  }

  String _makeSummary({bool shotSummary = false}) {
    if (widget.options.comment != null) {
      return widget.options.comment;
    }
    switch (_clauses.length) {
      case 0:
        return shotSummary ? 'Unkown' : 'Empty';
      case 1:
        if (_clauses[0].to == null) {
          return shotSummary ? 'Create' : 'Create a contract';
        }
        if (_clauses[0].data.length == 0) {
          return shotSummary ? 'Transfer' : 'Transfer VET';
        }
        return shotSummary ? 'Call' : 'Make contract call';
      default:
        return shotSummary ? 'Batch Call' : 'Perform a batch of clauses';
    }
  }

  Future<int> _estimateGas(String addr) async {
    int gas = _intrinsicGas;
    List<CallResult> results = await AccountAPI.call(
      widget.txMessages,
      caller: addr,
      gas: widget.options.gas,
    );
    String vmErr = '';
    for (CallResult result in results) {
      gas += (result.gasUsed.toDouble() * 1.2).toInt();
      if (result.reverted) {
        Uint8List data = hexToBytes(result.data);
        vmErr = '''Transaction may fail/revert\nVM error: ${result.vmError}''';
        if (data.length > 4 + 32) {
          DecodingResult<String> err = StringType().decode(data.buffer, 4 + 32);
          vmErr += '''\n${err.data}''';
        }
        throw VmErr(vmErr, gas);
      }
    }
    return gas;
  }

  Future<void> _updateFee() async {
    _estimatedFee = await initialBaseGasPrice() *
        BigInt.from((1 + _priority / 255) * 1e10) *
        BigInt.from(_totalGas) ~/
        BigInt.from(1e10);
  }

  Future<void> _completeByEntity(WalletEntity entity) async {
    dynamic updateUI = (int gas) async {
      _totalGas = widget.options.gas ?? gas;
      await _updateFee();
      setState(() {
        _swipeController.valueWith(shouldLoading: false, enabled: true);
      });
    };
    try {
      setState(() => _entity = entity);
      _account = await AccountAPI.get(_entity.address);
      updateUI(await _estimateGas(_entity.address));
      _vmErrStreamController.add(null);
    } catch (err) {
      if (err is VmErr) {
        _vmErrStreamController.add(err.msg);
        updateUI(err.gas);
      } else {
        print('-------$err');
      }
    }
  }

  Widget _buildWalletRow() {
    return RowElement(
      prefix: 'WALLET',
      content: WalletCard(
        name: _entity?.name ?? '',
        address: _entity?.address ?? '',
        vet: _account?.formatBalance ?? '--',
        vtho: _account?.formatEnergy ?? '--',
      ),
      onExpand: () async {
        WalletEntity newEntity = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Wallets(),
          ),
        );
        if (newEntity != null) {
          _swipeController.valueWith(shouldLoading: true, enabled: false);
          await _completeByEntity(newEntity);
        }
      },
    );
  }

  Widget _buildSummaryRow() {
    return RowElement(
      prefix: 'SUMMARY',
      content: Text(
        _makeSummary(),
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
      ),
      onExpand: widget.options.comment != null
          ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Summary(
                    title: 'Summary',
                    content: 's',
                  ),
                ),
              )
          : null,
    );
  }

  Widget _buildClausesRow() {
    return RowElement(
      prefix: 'Clauses',
      content: Text('${_clauses.length} Clauses'),
      onExpand: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Clauses(
            txMessages: widget.txMessages,
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityButton(int priority) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        _priority = priority;
        await _updateFee();
        setState(() {});
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 17, vertical: 17),
        child: Icon(
          MaterialCommunityIcons.getIconData('rocket'),
          color: _priority >= priority
              ? Theme.of(context).primaryColor
              : Theme.of(context).primaryTextTheme.display3.color,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPriorityRow() {
    return RowElement(
      prefix: 'Priority',
      content: Row(
        children: <Widget>[
          _buildPriorityButton(0),
          _buildPriorityButton(85),
          _buildPriorityButton(170),
          _buildPriorityButton(255),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Column(
      children: <Widget>[
        SizedBox(height: 8),
        Divider(thickness: 1),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTotalValue() {
    return Row(
      children: <Widget>[
        Text('Total Value'),
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '-${formatNum(fixed2Value(_totalVet))}',
                  textAlign: TextAlign.end,
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  'VET',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).primaryTextTheme.display2.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFee() {
    final Color color = Theme.of(context).primaryTextTheme.display2.color;
    return Row(
      children: <Widget>[
        Text('Estimate fee', style: TextStyle(color: color)),
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _swipeController.value.enabled
                      ? formatNum(fixed2Value(_estimatedFee))
                      : '--',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Theme.of(context).primaryTextTheme.display2.color,
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  'VTHO',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).primaryTextTheme.display2.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class VmErr implements Exception {
  const VmErr(this.msg, this.gas);

  final String msg;
  final int gas;
}
