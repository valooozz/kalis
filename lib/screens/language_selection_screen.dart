import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kalis/providers/core_providers.dart';
import 'package:kalis/screens/onboarding/onboarding_screen.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Choisissez votre langue\nChoose your language',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.tonalIcon(
                    onPressed: () => _select(context, ref, 'fr'),
                    icon: const Icon(Icons.language),
                    label: const Text('Français'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => _select(context, ref, 'en'),
                    icon: const Icon(Icons.language),
                    label: const Text('English'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    String languageCode,
  ) async {
    await ref.read(appLocaleProvider.notifier).setLocale(Locale(languageCode));
    if (!context.mounted) return;
    final onboardingSeen = await ref.read(onboardingSeenProvider.future);
    if (!context.mounted) return;
    context.go(onboardingSeen ? '/today' : '/onboarding');
  }
}
