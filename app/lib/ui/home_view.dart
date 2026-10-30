import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nada_format.dart';
import '../core/nada_theme.dart';
import '../data/nada_models.dart';
import '../state/nada_scope.dart';
import 'history_screen.dart';
import 'layout.dart';
import 'manifesto_screen.dart';
import 'medals_screen.dart';
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  NadaFootnote(
                                    label: 'Medallas',
                                    plain: true,
                                    onTap: () => Navigator.of(context).push(
                                      nadaRoute(const MedalsScreen()),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  NadaFootnote(
                                    label: 'Registro',
                                    plain: true,
                                    onTap: () => Navigator.of(context).push(
                                      nadaRoute(const HistoryScreen()),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Hoy, ${journalDate(DateTime.now())}',
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
                                  const NadaSectionLabel('En total'),
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
                            const SizedBox(height: 34),
                            const NadaSectionLabel(
                              '¿Cuánto tiempo?',
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
                    label: 'Ajustes',
                    onTap: () => showNadaSettings(context),
                  ),
                  right: NadaFootnote(
                    label: 'Manifiesto',
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
