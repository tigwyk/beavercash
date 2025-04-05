import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:beavercash/components/infocard.dart';

class CryptoCard extends StatelessWidget {
  final log = Logger('CryptoCardLogs');
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InfoCard(
      title: 'Crypto',
      subtitle: 'BTC, ETH & More',
      bodyContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.currency_bitcoin,
                color: Colors.amber,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '\$0.00',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'No crypto assets yet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      buttons: [
        ButtonInfo(
          label: 'Buy',
          onPressed: () {
            log.info('Buy crypto tapped');
          },
        ),
      ],
      onTap: () {
        log.info('Crypto card tapped');
      },
    );
  }
}