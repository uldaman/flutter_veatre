import 'package:flutter/material.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/enterPassword.dart';

class Welcome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 30, top: 20),
                child: Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 180,
                    height: 180,
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 60,
                      child: Text(
                        'Connet is designed to provide the superior user experiences for VeChain Apps,and serves as the dApp enviroment to provide unlimited potential for developers and users.',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color:
                              Theme.of(context).primaryTextTheme.display2.color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 80),
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 170,
                  height: 44,
                  child: commonButton(
                    context,
                    'Start',
                    () async {
                      await Navigator.push(
                        context,
                        new MaterialPageRoute(
                          builder: (context) => new EnterPassword(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
