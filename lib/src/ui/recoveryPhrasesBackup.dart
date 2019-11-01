import 'package:flutter/material.dart';
import 'package:veatre/src/ui/verifyRecoveryPhrases.dart';

class RecoveryPhraseBackup extends StatefulWidget {
  final bool hasBackup;
  final String mnemonic;
  final String rootRouteName;

  RecoveryPhraseBackup({
    Key key,
    @required this.hasBackup,
    @required this.mnemonic,
    @required this.rootRouteName,
  }) : super(key: key);

  _RecoveryPhraseBackupState createState() => _RecoveryPhraseBackupState();
}

class _RecoveryPhraseBackupState extends State<RecoveryPhraseBackup> {
  List<String> mnemonicWords;

  @override
  void initState() {
    super.initState();
    setState(() {
      mnemonicWords = widget.mnemonic.split(' ');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recovery Phrases'),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 50,
              child: widget.hasBackup
                  ? SizedBox()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Icon(
                            Icons.error,
                            color: Theme.of(context).errorColor,
                            size: 18,
                          ),
                        ),
                        Text(
                          'Not backed up',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.title.color,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
            ),
            Expanded(
              child: Container(
                child: Center(
                  child: SizedBox(
                    height: 300,
                    child: GridView.builder(
                      padding: EdgeInsets.all(0),
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 0,
                        mainAxisSpacing: 0,
                        childAspectRatio: 2,
                      ),
                      itemCount: mnemonicWords.length,
                      itemBuilder: (context, index) {
                        return Align(
                          alignment: Alignment.center,
                          child: Text(
                            mnemonicWords[index],
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.grey[250],
              height: 280,
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 60,
                        child: Text(
                          'Recovery phrases are used to recover your wallet.Please write them down and keep them in a secure place.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .primaryTextTheme
                                .display2
                                .color,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 60,
                    height: 44,
                    child: FlatButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        side: BorderSide(
                          color: Theme.of(context).primaryTextTheme.title.color,
                          width: 1,
                        ),
                      ),
                      color: Theme.of(context).primaryColor,
                      child: Text(
                        "Verify Recovery Phrases",
                        style: TextStyle(
                          color: Theme.of(context).accentColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          new MaterialPageRoute(
                            builder: (context) => new VerifyRecoveryPhrase(
                              rootRouteName: widget.rootRouteName,
                              mnemonic: widget.mnemonic,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
