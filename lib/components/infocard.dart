import 'package:flutter/material.dart';

class ButtonInfo {
  final String label;
  final VoidCallback onPressed;

  ButtonInfo({
    required this.label,
    required this.onPressed,
  });
}

class InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? bodyText;
  final Widget? bodyContent;
  final List<ButtonInfo>? buttons;
  final VoidCallback? onTap;

  const InfoCard({
    Key? key,
    required this.title,
    required this.subtitle,
    this.bodyText,
    this.bodyContent,
    this.buttons,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Keep this to prevent expansion issues
            children: [
              // Header with title and subtitle
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 16),
              
              // Card body - either text or custom content
              if (bodyText != null)
                Container(
                  width: double.infinity,
                  child: Text(
                    bodyText!,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              if (bodyContent != null) 
                Container(
                  width: double.infinity,
                  child: bodyContent!,
                ),
              
              // Buttons section if any
              if (buttons != null && buttons!.isNotEmpty) ...[
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: buttons!.map((button) => 
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: TextButton(
                        onPressed: button.onPressed,
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          textStyle: TextStyle(fontWeight: FontWeight.bold),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(button.label),
                      ),
                    )
                  ).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final String action;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  
  QuickActionCard({
    required this.action, 
    required this.icon,
    this.color,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InfoCard(
      title: action,
      subtitle: 'Quick Action',
      bodyContent: Center(
        child: Icon(
          icon,
          size: 36,
          color: color ?? colorScheme.primary,
        ),
      ),
      onTap: onTap ?? () {
        print('$action tapped');
      },
    );
  }
}
