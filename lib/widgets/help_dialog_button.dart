import 'package:flutter/material.dart';

class HelpDialogButton extends StatelessWidget {
  const HelpDialogButton({
    super.key,
    required this.tooltip,
    required this.title,
    required this.content,
    required this.closeLabel,
  });

  final String tooltip;
  final String title;
  final String content;
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: const Icon(Icons.help_outline),
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(closeLabel),
              ),
            ],
          ),
        );
      },
    );
  }
}
