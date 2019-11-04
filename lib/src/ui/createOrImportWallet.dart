import 'package:flutter/material.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/createWallet.dart';
import 'package:veatre/src/ui/importWallet.dart';

class CreateOrImportWallet extends StatelessWidget {
  final String fromRouteName;

  CreateOrImportWallet({
    Key key,
    @required this.fromRouteName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 10,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.all(0),
                      icon: Icon(Icons.arrow_back_ios),
                      onPressed: () async {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 20,
                      left: 30,
                    ),
                    child: SizedBox(
                      width: 200,
                      child: Text(
                        'Get Started',
                        textAlign: TextAlign.left,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(40)),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 120,
                      height: MediaQuery.of(context).size.width - 120,
                      color: Colors.grey,
                      //TODO LOGO
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 60,
                    height: 44,
                    child: commonButton(
                      context,
                      'Create a new wallet',
                      () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CreateWallet(
                              rootRouteName: fromRouteName,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 15),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 60,
                      height: 44,
                      child: commonButton(
                        context,
                        'Import existed wallet',
                        () async {
                          await Navigator.push(
                            context,
                            new MaterialPageRoute(
                              builder: (context) => new ImportWallet(
                                rootRouteName: fromRouteName,
                              ),
                            ),
                          );
                        },
                        color: Colors.transparent,
                        textColor:
                            Theme.of(context).primaryTextTheme.title.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
