import 'package:flutter/material.dart';

import '../core/nada_format.dart';
import '../core/nada_theme.dart';
import '../data/nada_models.dart';
import '../state/nada_scope.dart';
import 'widgets/nada_widgets.dart';

/// The whole medal economy, in one small sheet.
Future<void> showNadaMedals(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: NadaColors.voidBlack,
    barrierColor: const Color(0xB3000000),
    builder: (sheetContext) => const _MedalsSheet(),
  );
}

class _MedalsSheet extends StatelessWidget {
  const _MedalsSheet();

  @override
  Widget build(BuildContext context) {
    final stats = NadaScope.of(context).stats;
    final earned = stats.medalsThisWeek;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NadaHairline(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'medallas',
                        style: NadaType.title.copyWith(fontSize: 36),
                      ),
                      const Spacer(),
                      NadaFootnote(
                        label: 'listo',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      NadaMedal(
                        size: 64,
                        filled: earned > 0,
                        semanticLabel: '$earned medallas esta semana',
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medalLabel(earned),
                              style: NadaType.title.copyWith(fontSize: 32),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'esta semana · ${stats.medalsTotal} en total',
                              style: NadaType.label.copyWith(
                                fontSize: 16,
                                color: NadaColors.ash,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'una medalla por cada $nadaMinutesPerMedal minutos de nada. '
                    'la semana empieza el lunes y el contador vuelve a cero, '
                    'pero las que ya ganaste se quedan en tu colección.',
                    style: NadaType.bodyMuted.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  const NadaHairline(),
                  const SizedBox(height: 18),
                  Text(
                    'te faltan ${stats.minutesToNextMedal} min para la siguiente.',
                    style: NadaType.body.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'no sirven para nada. ese es el punto.',
                    style: NadaType.italic.copyWith(
                      fontSize: 18,
                      color: NadaColors.faint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
