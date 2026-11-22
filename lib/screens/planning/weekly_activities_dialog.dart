import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kalis/core/utils/firestore_write_utils.dart';
import 'package:kalis/l10n/app_localizations.dart';
import '../../models/weekly_activities_model.dart';
import '../../providers/core_providers.dart';
import '../../providers/weekly_activities_providers.dart';

class WeeklyActivitiesDialog extends ConsumerStatefulWidget {
  const WeeklyActivitiesDialog({super.key});

  @override
  ConsumerState<WeeklyActivitiesDialog> createState() =>
      _WeeklyActivitiesDialogState();
}

class _WeeklyActivitiesDialogState
    extends ConsumerState<WeeklyActivitiesDialog> {
  final _controllers = List.generate(7, (_) => TextEditingController());
  bool _initialized = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lbl = AppLocalizations.of(context)!;
    final activitiesAsync = ref.watch(weeklyActivitiesProvider);

    return AlertDialog(
      title: Text(lbl.weeklyActivitiesDialogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: activitiesAsync.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('Erreur : $error'),
          data: (activities) {
            if (!_initialized) {
              for (
                var weekday = DateTime.monday;
                weekday <= DateTime.sunday;
                weekday++
              ) {
                _controllers[weekday - 1].text =
                    activities.activities[weekday] ?? '';
              }
              _initialized = true;
            }

            final locale = Localizations.localeOf(context).languageCode;
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.7,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 7,
                itemBuilder: (context, index) {
                  final weekday = index + 1;
                  final weekdayName = DateFormat.EEEE(
                    locale,
                  ).format(DateTime(2024, 1, weekday));
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _controllers[index],
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText:
                            '${weekdayName[0].toUpperCase()}${weekdayName.substring(1)}',
                        hintText: lbl.weeklyActivityHint,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(lbl.buttonCancel),
        ),
        FilledButton(
          onPressed: _initialized ? _save : null,
          child: Text(lbl.buttonSave),
        ),
      ],
    );
  }

  void _save() {
    final repository = ref.read(weeklyActivitiesRepositoryProvider);
    if (repository == null) return;

    final activities = <int, String>{};
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      final text = _controllers[weekday - 1].text.trim();
      if (text.isNotEmpty) activities[weekday] = text;
    }

    detachFirestoreWrite(
      repository.save(WeeklyActivitiesModel(activities: activities)),
      operation: 'saving weekly activities',
    );
    Navigator.of(context).pop();
  }
}
