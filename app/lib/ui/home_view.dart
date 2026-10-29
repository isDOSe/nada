import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nada_format.dart';
import '../core/nada_theme.dart';
import '../data/nada_models.dart';
import '../state/nada_scope.dart';
import 'history_screen.dart';
import 'layout.dart';
import 'manifesto_screen.dart';
import 'medals_sheet.dart';
import 'settings_sheet.dart';
import 'widgets/nada_widgets.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NadaScope.of(context);
    final stats = controller.stats;
    final settings = controller.settings;

    final quick = settings.quickMinutes;
    final extraGoal = quick.contains(settings.goalMinutes)
        ? null
        : settings.goalMinutes;
    final freeChoice = NadaChoice(
      label: 'sin límite',
      detail: 'sin meta',
      selected: settings.mode == NadaMode.free,
      onTap: () =>
          controller.updateSettings(settings.copyWith(mode: NadaMode.free)),
    );
    final goalChoices = <Widget>[
      for (var index = 0; index < quick.length; index++)
        NadaChoice(
          label: nadaPresetNames[index],
          detail: '${quick[index]} min',
          selected:
              settings.mode == NadaMode.goal &&
              settings.goalMinutes == quick[index],
          onTap: () => controller.updateSettings(
            settings.copyWith(mode: NadaMode.goal, goalMinutes: quick[index]),
          ),
        ),
      if (extraGoal != null)
        NadaChoice(
          label: '$extraGoal min',
          detail: 'personalizado',
          selected:
              settings.mode == NadaMode.goal &&
              settings.goalMinutes == extraGoal,
          onTap: () => controller.updateSettings(
            settings.copyWith(mode: NadaMode.goal, goalMinutes: extraGoal),
          ),
        ),
    ];

    return NadaScreen(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 10, 26, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            NadaHeader(
                              trailing: NadaFootnote(
                                label: 'registro',
                                plain: true,
                                onTap: () => Navigator.of(
                                  context,
                                ).push(nadaRoute(const HistoryScreen())),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'hoy, ${journalDate(DateTime.now())}',
                              style: NadaType.label.copyWith(
                                fontSize: 16,
                                color: NadaColors.ash,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'nada!',
                                style: NadaType.hero.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'la app para hacer nada. o algo. depende.',
                              style: NadaType.italic.copyWith(fontSize: 19),
                            ),
                            const SizedBox(height: 34),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Navigator.of(
                                context,
                              ).push(nadaRoute(const HistoryScreen())),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const NadaSectionLabel('en total'),
                                  const SizedBox(height: 6),
                                  Text(
                                    compactDuration(stats.total),
                                    style: NadaType.number.copyWith(
                                      fontSize: 46,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    stats.sessionCount == 0
                                        ? 'tu primera sesión de nada empieza cuando quieras.'
                                        : '${sessionCountLabel(stats.sessionCount)} · ${streakLabel(stats.streakDays)}',
                                    style: NadaType.label.copyWith(
                                      fontSize: 16,
                                      color: NadaColors.ash,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            _HomeMedals(stats: stats),
                            const SizedBox(height: 22),
                            const NadaSectionLabel(
                              '¿cuánto tiempo?',
                              color: NadaColors.bone,
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [freeChoice, ...goalChoices],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              settings.mode == NadaMode.free
                                  ? 'cuenta hacia arriba. tú decides cuándo parar de no hacer nada.'
                                  : 'te aviso cuando llegues. luego decides si sigues sin hacer nada.',
                              style: NadaType.bodyMuted.copyWith(
                                fontSize: 16,
                                color: NadaColors.ash,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 10, 26, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NadaButton(
                  label: 'empezar a no hacer nada',
                  semanticLabel: 'Empezar una sesión de nada',
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    controller.startSession();
                  },
                ),
                const SizedBox(height: 18),
                const NadaHairline(),
                const SizedBox(height: 4),
                NadaFooterRow(
                  left: NadaFootnote(
                    label: 'ajustes',
                    onTap: () => showNadaSettings(context),
                  ),
                  right: NadaFootnote(
                    label: 'manifiesto',
                    onTap: () => Navigator.of(
                      context,
                    ).push(nadaRoute(const ManifestoScreen())),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeMedals extends StatelessWidget {
  const _HomeMedals({required this.stats});

  final NadaStats stats;

  @override
  Widget build(BuildContext context) {
    final earned = stats.medalsThisWeek;
    final caption = earned == 0
        ? stats.medalsTotal == 0
              ? 'cada 45 min de nada. te faltan ${stats.minutesToNextMedal}.'
              : 'cada 45 min de nada. te faltan ${stats.minutesToNextMedal} · ${stats.medalsTotal} en total'
        : '${stats.minutesToNextMedal} min para la siguiente · ${stats.medalsTotal} en total';

    return Semantics(
      button: true,
      label: 'Ver las medallas: $earned esta semana',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showNadaMedals(context),
        child: Row(
          children: [
            NadaMedal(
              filled: earned > 0,
              semanticLabel: earned == 0
                  ? 'sin medallas todavía'
                  : '$earned medallas esta semana',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    earned == 0
                        ? 'ninguna esta semana'
                        : '${medalLabel(earned)} esta semana',
                    style: NadaType.body.copyWith(fontSize: 17, height: 1.2),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    caption,
                    style: NadaType.label.copyWith(
                      fontSize: 14,
                      height: 1.35,
                      color: NadaColors.ash,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'ver',
              style: NadaType.label.copyWith(
                fontSize: 14,
                color: NadaColors.faint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
