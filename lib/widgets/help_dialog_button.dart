import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/providers/core_providers.dart';

class HelpDialogButton extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(helpBubblesEnabledProvider);
    if (!enabled) return const SizedBox.shrink();

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
