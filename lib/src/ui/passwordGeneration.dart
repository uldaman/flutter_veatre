import 'package:flutter/material.dart';
import 'package:veatre/src/ui/enterPassword.dart';

class PasswordGeneration extends StatelessWidget {
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
            Padding(
              padding: EdgeInsets.only(top: 40),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(40)),
                child: Container(
                  width: MediaQuery.of(context).size.width - 120,
                  height: MediaQuery.of(context).size.width - 120,
                  color: Colors.grey[350],
                  //TODO LOGO
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 40),
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 60,
                child: Text(
                  'Sync is designed to provide the superior user experiences for VeChain Apps,and serves as the dApp enviroment to provide unlimited potential for developers and users.',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 170,
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
                      'Start',
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
                          builder: (context) => new EnterPassword(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
