import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nada_format.dart';
import '../core/nada_theme.dart';
import '../data/nada_models.dart';
import '../state/nada_scope.dart';
import 'layout.dart';
import 'widgets/nada_widgets.dart';

class SummaryView extends StatelessWidget {
  const SummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NadaScope.of(context);
    final session = controller.lastFinished;
    if (session == null) return const SizedBox.shrink();

    final stats = controller.stats;
    final completed = session.completed;
    final isFree = session.mode == NadaMode.free;
    final sessionNumber = stats.sessionCount;

    return NadaScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NadaHeader(
            trailing: NadaFootnote(
              label: 'cerrar',
              onTap: controller.dismissSummary,
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NadaSectionLabel(
                  completed
                      ? 'meta cumplida · sesión $sessionNumber'
                      : 'sesión $sessionNumber guardada',
                  color: NadaColors.ash,
                ),
                const SizedBox(height: 18),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    compactDuration(session.duration),
                    style: NadaType.title.copyWith(
                      fontSize: 76,
                      letterSpacing: -2,
                    ),
                  ),
                ),
                Text(
                  'de nada.',
                  style: NadaType.italic.copyWith(
                    fontSize: 28,
                    color: NadaColors.ash,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  completed
                      ? 'llegaste a la meta sin producir absolutamente nada. impecable.'
                      : isFree
                      ? 'no estaban en tu agenda. ahora están en tu registro.'
                      : 'cortaste antes de la meta. igual cuenta.',
                  style: NadaType.body.copyWith(
                    fontSize: 20,
                    color: NadaColors.ash,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'en total ${compactDuration(stats.total)} · ${sessionCountLabel(stats.sessionCount)}',
                  style: NadaType.label.copyWith(
                    fontSize: 16,
                    color: NadaColors.ash,
                  ),
                ),
              ],
            ),
          ),
          NadaButton(
            label: 'seguir sin hacer nada',
            onPressed: () {
              HapticFeedback.mediumImpact();
              controller.startSession();
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: NadaButton(
              label: 'volver al inicio',
              kind: NadaButtonKind.quiet,
              expand: false,
              onPressed: controller.dismissSummary,
            ),
          ),
        ],
      ),
    );
  }
}
