import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:beavercash/components/infocard.dart';

class SavingsCard extends StatelessWidget {
  final log = Logger('SavingsCardLogs');
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InfoCard(
      title: 'Savings',
      subtitle: 'Growth & Interest',
      bodyContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.savings_outlined,
                color: colorScheme.primary,
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
            'Earn 2.5% APY',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
      buttons: [
        ButtonInfo(
          label: 'View',
          onPressed: () {
            log.info('View savings tapped');
          },
        ),
      ],
      onTap: () {
        log.info('Savings card tapped');
      },
    );
  }
}