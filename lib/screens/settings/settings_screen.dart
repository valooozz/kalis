import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalis/l10n/app_localizations.dart';
import '../../providers/core_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbl = AppLocalizations.of(context)!;
    final isLinkedToGoogle = ref.watch(isLinkedToGoogleProvider);

    return Scaffold(
      appBar: AppBar(title: Text(lbl.settingsTitle)),
      body: ListView(
        children: [
          // Section compte
          _SectionHeader(label: lbl.settingsAccountSection),
          if (!isLinkedToGoogle)
            _SettingsTile(
              icon: Icons.account_circle,
              title: lbl.settingsLinkGoogle,
              subtitle: lbl.settingsLinkGoogleSubtitle,
              onTap: () => _linkGoogle(context, ref, lbl),
            )
          else
            _SettingsTile(
              icon: Icons.check_circle,
              title: lbl.settingsLinkedGoogle,
              subtitle: ref.watch(authStateProvider).valueOrNull?.email ?? '',
              iconColor: Colors.green,
              onTap: null,
            ),
        ],
      ),
    );
  }

  Future<void> _linkGoogle(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations lbl,
  ) async {
    try {
      final googleSignIn = ref.read(googleSignInProvider);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Liaison du compte anonyme au compte Google
      final user = FirebaseAuth.instance.currentUser;
      await user?.linkWithCredential(credential);

      // Forcer le rechargement pour mettre à jour les providers
      await FirebaseAuth.instance.currentUser?.reload();
      ref.invalidate(isLinkedToGoogleProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(lbl.settingsLinkGoogleSuccess)));
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        // Si le compte Google est déjà lié à un autre compte Firebase
        if (e.code == 'credential-already-in-use') {
          _showAlreadyLinkedDialog(context, ref, e.credential!, lbl);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(lbl.settingsLinkGoogleError)));
        }
      }
    }
  }

  Future<void> _showAlreadyLinkedDialog(
    BuildContext context,
    WidgetRef ref,
    AuthCredential credential,
    AppLocalizations lbl,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lbl.settingsAlreadyLinkedTitle),
        content: Text(lbl.settingsAlreadyLinkedContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(lbl.buttonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(lbl.buttonConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Connexion avec le compte Google existant
    await FirebaseAuth.instance.signInWithCredential(credential);
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
    );
  }
}
