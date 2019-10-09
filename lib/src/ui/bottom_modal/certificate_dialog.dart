import 'package:flutter/material.dart';
import 'package:veatre/src/ui/bottom_modal/wallet_card.dart';
import 'package:veatre/src/ui/bottom_modal/row_element.dart';

class CertificateDialog extends StatelessWidget {
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
          prefix: 'TYPE',
          content: Text('DENTIFICATION'),
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
            onExpand: () => print(1),
          ),
        ),
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
}
