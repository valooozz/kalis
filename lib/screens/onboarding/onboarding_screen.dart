import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kalis/l10n/app_localizations.dart';
import 'package:kalis/models/figure_model.dart';
import 'package:kalis/widgets/figure_square_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

const onboardingSeenKey = 'onboarding_seen';

final onboardingSeenProvider = FutureProvider<bool>((ref) async {
  final preferences = await SharedPreferences.getInstance();
  return preferences.getBool(onboardingSeenKey) ?? false;
});

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(onboardingSeenKey, true);
    ref.invalidate(onboardingSeenProvider);
    if (!mounted) return;
    context.go('/today');
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lbl = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(lbl.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _OnboardingPage(
                    illustration: _FiguresIllustration(lbl: lbl),
                    title: lbl.onboardingFiguresTitle,
                    description: lbl.onboardingFiguresDescription,
                  ),
                  _OnboardingPage(
                    illustration: _PlanningIllustration(lbl: lbl),
                    title: lbl.onboardingPlanningTitle,
                    description: lbl.onboardingPlanningDescription,
                  ),
                  _OnboardingPage(
                    illustration: _ProgressIllustration(lbl: lbl),
                    title: lbl.onboardingProgressTitle,
                    description: lbl.onboardingProgressDescription,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final active = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: active ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => _controller.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                              ),
                              child: Text(
                                lbl.onboardingPrevious,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: _currentPage == 0 ? 1 : 2,
                        child: SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _currentPage == 2 ? _finish : _next,
                            child: Text(
                              _currentPage == 2
                                  ? lbl.onboardingStart
                                  : lbl.onboardingNext,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.illustration,
    required this.title,
    required this.description,
  });

  final Widget illustration;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 360, child: illustration),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _FiguresIllustration extends StatelessWidget {
  const _FiguresIllustration({required this.lbl});

  final AppLocalizations lbl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        width: 320,
        height: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IllustrationTile(
              state: FigureState.toLearn,
              label: lbl.stateToLearn,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
            ),
            const SizedBox(height: 10),
            _IllustrationTile(
              state: FigureState.learning,
              label: lbl.stateLearning,
              backgroundColor: colors.secondaryContainer,
              foregroundColor: colors.onSecondaryContainer,
            ),
            const SizedBox(height: 10),
            _IllustrationTile(
              state: FigureState.learned,
              label: lbl.stateLearned,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanningIllustration extends StatelessWidget {
  const _PlanningIllustration({required this.lbl});

  final AppLocalizations lbl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        width: 340,
        height: 330,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          children: [
            Text(
              '${lbl.addFigure} · Aujourd\'hui',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('Salle'),
                  selected: true,
                  showCheckmark: false,
                  onSelected: (_) {},
                ),
                ChoiceChip(
                  label: const Text('Parc'),
                  selected: false,
                  showCheckmark: false,
                  onSelected: (_) {},
                ),
              ],
            ),
            CheckboxListTile(
              value: false,
              onChanged: (_) {},
              title: Text(lbl.showLearnedFigures),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Divider(height: 12),
            _MiniFigureCard(
              name: 'Muscle-Up',
              color: FigureColor.green,
              state: FigureState.learned,
            ),
            const SizedBox(height: 4),
            _MiniFigureCard(
              name: 'Front Lever',
              color: FigureColor.blue,
              state: FigureState.learning,
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: null, child: Text(lbl.buttonClose)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressIllustration extends StatelessWidget {
  const _ProgressIllustration({required this.lbl});

  final AppLocalizations lbl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        width: 340,
        height: 270,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: colors.surfaceContainerLow,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      lbl.todayScreenTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.sticky_note_2, size: 20),
                  const SizedBox(width: 8),
                  Icon(Icons.fitness_center, size: 20, color: colors.primary),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 112,
                      child: FigureSquareCard(
                        figure: const FigureModel(
                          id: 'front-lever',
                          name: 'Front Lever',
                          color: FigureColor.blue,
                          state: FigureState.learning,
                        ),
                        isDone: true,
                        onTap: () {},
                        onLongPress: () {},
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 112,
                      child: FigureSquareCard(
                        figure: const FigureModel(
                          id: 'muscle-up',
                          name: 'Muscle-Up',
                          color: FigureColor.green,
                          state: FigureState.learned,
                        ),
                        isDone: false,
                        onTap: () {},
                        onLongPress: () {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniFigureCard extends StatelessWidget {
  const _MiniFigureCard({
    required this.name,
    required this.color,
    required this.state,
  });

  final String name;
  final FigureColor color;
  final FigureState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color.color, width: 8)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(state.icon, size: 20, color: color.color),
          ],
        ),
      ),
    );
  }
}

class _IllustrationTile extends StatelessWidget {
  const _IllustrationTile({
    required this.state,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final FigureState state;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(state.icon, color: foregroundColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
