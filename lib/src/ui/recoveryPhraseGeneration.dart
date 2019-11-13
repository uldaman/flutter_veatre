import 'package:flutter/material.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/verifyRecoveryPhrases.dart';

class RecoveryPhraseGeneration extends StatefulWidget {
  final String mnemonic;
  final String rootRouteName;

  RecoveryPhraseGeneration({
    Key key,
    @required this.mnemonic,
    @required this.rootRouteName,
  }) : super(key: key);

  _RecoveryPhraseGenerationState createState() =>
      _RecoveryPhraseGenerationState();
}

class _RecoveryPhraseGenerationState extends State<RecoveryPhraseGeneration> {
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
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Recovery Phrases',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 50,
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
                    child: Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 60,
                        child: Text(
                          'Recovery phrases are used to recover your wallet.Please write them down and keep them in a secure place.',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 60,
                    height: 44,
                    child: commonButton(
                      context,
                      "Done,let's verify",
                      () async {
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
                  Padding(
                    padding: EdgeInsets.only(
                      top: 15,
                    ),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 60,
                      height: 44,
                      child: commonButton(
                        context,
                        'Skip Now',
                        () async {
                          Navigator.popUntil(
                            context,
                            ModalRoute.withName(widget.rootRouteName),
                          );
                        },
                        color: Colors.transparent,
                        textColor:
                            Theme.of(context).primaryTextTheme.title.color,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
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
