import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:beavercash/components/infocard.dart';

class TransactionHistoryCard extends StatelessWidget {
  final log = Logger('TransactionHistoryCardLogs');
  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Transaction History',
      subtitle: 'Recent Transactions',
      bodyText: 'View your recent transactions here.',
      onTap: () {
        log.info('Transaction history card tapped');
      },
    );
  }
}
