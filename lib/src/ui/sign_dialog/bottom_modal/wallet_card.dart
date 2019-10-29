import 'package:flutter/material.dart';
import 'package:veatre/src/ui/picasso.dart';
import 'package:veatre/src/utils/common.dart';

class WalletCard extends StatelessWidget {
  WalletCard({
    Key key,
    @required this.name,
    @required this.address,
    @required this.vet,
    @required this.vtho,
  }) : super(key: key);

  final String name;
  final String address;
  final String vet;
  final String vtho;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWalletInfo(context),
        _buildBalance(context, 'VET', vet),
        _buildBalance(context, 'VTHO', vtho),
      ],
    );
  }

  Widget _buildBalance(BuildContext context, String suffix, String value) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
          ),
        ),
        SizedBox(
          width: 40,
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
          child: Picasso(
            '0x$address',
            size: 20,
            borderRadius: 3,
          ),
        ),
        Flexible(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          ' (0x${abbreviate(address)})',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).accentTextTheme.title.color,
          ),
        ),
      ],
    );
  }
}
