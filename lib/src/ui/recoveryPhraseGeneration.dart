import 'package:flutter/material.dart';
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
                color: Theme.of(context).primaryColor,
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
                    child: FlatButton(
                      color: Theme.of(context).textTheme.title.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        side: BorderSide(
                          color: Theme.of(context).textTheme.title.color,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        "Done,let's verify",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
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
                  Padding(
                    padding: EdgeInsets.only(
                      top: 15,
                    ),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 180,
                      height: 44,
                      child: FlatButton(
                        child: Text(
                          'Skip Now',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        color: Colors.transparent,
                        onPressed: () async {
                          Navigator.popUntil(
                            context,
                            ModalRoute.withName(widget.rootRouteName),
                          );
                        },
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

  TextField textField({
    TextEditingController controller,
    String hitText,
    String errorText,
  }) {
    return TextField(
      controller: controller,
      maxLength: 20,
      autofocus: true,
      decoration: InputDecoration(
        hintText: hitText,
        errorText: errorText,
      ),
      style: Theme.of(context).textTheme.body1,
    );
  }
}
