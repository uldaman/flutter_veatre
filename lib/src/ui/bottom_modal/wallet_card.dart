import 'package:flutter/material.dart';

class WalletCard extends StatelessWidget {
  WalletCard({
    Key key,
    @required this.name,
    @required this.vet,
    @required this.vtho,
  }) : super(key: key);

  final String name;
  final double vet;
  final double vtho;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWalletInfo(context),
        _buildBalance(context, 'VET', '0.00'),
        _buildBalance(context, 'VTHO', '1948.29'),
      ],
    );
  }

  Widget _buildBalance(BuildContext context, String suffix, String value) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 20,
          child: Text(
            value,
            textAlign: TextAlign.end,
          ),
        ),
        Spacer(flex: 1),
        Expanded(
          flex: 4,
          child: Text(
            suffix,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).accentTextTheme.title.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletInfo(BuildContext context) {
    return Row(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(right: 5),
          child: Icon(
            Icons.portrait,
            size: 25,
            color: Colors.green,
          ),
        ),
        Flexible(
          child: Text(
            'Wassssssssssss',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '(0x1234…1234)',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).accentTextTheme.title.color,
          ),
        ),
      ],
    );
  }
}
