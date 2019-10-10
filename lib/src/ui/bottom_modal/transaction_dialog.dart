import 'package:flutter/material.dart';
import 'package:veatre/src/ui/bottom_modal/wallet_card.dart';
import 'package:veatre/src/ui/bottom_modal/row_element.dart';
import 'package:veatre/src/ui/bottom_modal/summary.dart';

class TransactionDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        RowElement(
          prefix: 'WALLET',
          content: WalletCard(
            name: 'WalletName(0x1234...1234)',
            vet: 0.0,
            vtho: 1948.29,
          ),
          onExpand: () => print(1),
        ),
        _buildDivider(),
        RowElement(
          prefix: 'Priority',
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Icon(Icons.access_alarm, color: Colors.blue),
              Icon(Icons.access_alarm, color: Colors.blue),
              Icon(Icons.access_alarm, color: Colors.blue),
              Icon(Icons.access_alarm, color: Colors.blue),
            ],
          ),
        ),
        _buildDivider(),
        Expanded(
          flex: 1,
          child: RowElement(
            prefix: 'SUMMARY',
            content: LayoutBuilder(
              builder: (context, constraints) {
                double fontSize = 14.0;
                return Text(
                  "DENTIFICATIONDDENTIFICATIONDDENTIFICATIONDDENTIFICATIONDDENTIFICATIONDDENTIFICATIONDDENTIFICATIONDDENTIFICATIONDDENTIFICATIONDDENTIFICATIONDDENTIFICATIONDDENTIFICATIONDDENTIFICATIONDDENTIFICATIONDDENTIFICATIOND",
                  style: TextStyle(fontSize: fontSize),
                  maxLines: constraints.maxHeight ~/ fontSize - 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
            onExpand: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Summary(
                  title: 'Summary',
                  content: 's',
                ),
              ),
            ),
          ),
        ),
        _buildDivider(),
        RowElement(
          prefix: 'Clauses',
          content: Text('2 Clauses'),
          onExpand: () => print(1),
        ),
        _buildDivider(),
        _buildTotalValue(context),
        _buildDivider(),
        Spacer(
          flex: 2,
        )
      ],
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

  Widget _buildTotalValue(BuildContext context) {
    final Color color = Theme.of(context).accentTextTheme.title.color;
    return Row(
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Total Value'),
            Text(
              'Estimate fee',
              style: TextStyle(color: color),
            ),
          ],
        ),
        Expanded(
          child: Column(
            children: <Widget>[
              _buildBalance(context, 'VET', '-10.00'),
              _buildBalance(context, 'VTHO', '67.52'),
            ],
          ),
        ),
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
}
