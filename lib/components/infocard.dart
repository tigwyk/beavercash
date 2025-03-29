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
  final double minWidth;
  final double maxWidth;
  final bool expanded;

  const InfoCard({
    Key? key,
    required this.title,
    required this.subtitle,
    this.bodyText,
    this.bodyContent,
    this.buttons,
    this.onTap,
    this.minWidth = 150.0,
    this.maxWidth = double.infinity,
    this.expanded = true,
  }) : assert(bodyText != null || bodyContent != null, 'Either bodyText or bodyContent must be provided'),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget cardWrapper = expanded 
      ? Expanded(
          child: _buildCardContent(context),
        )
      : Flexible(
          child: _buildCardContent(context),
        );
    
    return cardWrapper;
  }

  Widget _buildCardContent(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final titleStyle = TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  );
                  final subtitleStyle = TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  );
                  
                  if (constraints.maxWidth < 250) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: titleStyle,
                          textScaler: TextScaler.linear(1.2),
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: subtitleStyle,
                          textScaler: TextScaler.linear(0.8),
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Text(
                          title,
                          style: titleStyle,
                          textScaler: TextScaler.linear(1.2),
                        ),
                        Spacer(),
                        Text(
                          subtitle,
                          style: subtitleStyle,
                          textScaler: TextScaler.linear(0.8),
                        ),
                      ],
                    );
                  }
                },
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: bodyContent ?? Text(
                  bodyText!,
                  textScaler: TextScaler.linear(1.6),
                  textAlign: TextAlign.left,
                ),
              ),
              if (buttons != null && buttons!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 250 && buttons!.length > 1) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: buttons!.map((button) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: FilledButton.tonal(
                                onPressed: button.onPressed,
                                child: Text(button.label),
                              ),
                            );
                          }).toList(),
                        );
                      } else {
                        return Row(
                          children: _buildButtonsRow(buttons!),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  } 
  List<Widget> _buildButtonsRow(List<ButtonInfo> buttons) {
    final List<Widget> buttonWidgets = [];
    
    for (int i = 0; i < buttons.length; i++) {
      buttonWidgets.add(
        FilledButton.tonal(
          onPressed: buttons[i].onPressed,
          child: Text(buttons[i].label),
        ),
      );
      
      if (i < buttons.length - 1) {
        buttonWidgets.add(Spacer());
      }
    }
    
    return buttonWidgets;
  }
}

class QuickActionCard extends StatelessWidget {
  final String action;
  
  QuickActionCard(this.action);
  
  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: action,
      subtitle: 'Quick Action',
      bodyContent: Center(
        child: Icon(
          action == 'Send' ? Icons.send :
          action == 'Request' ? Icons.request_page :
          Icons.payment,
          size: 36,
        ),
      ),
      onTap: () {
        print('$action tapped');
      },
    );
  }
}
