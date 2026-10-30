import 'package:flutter/material.dart';

import '../core/nada_format.dart';
import '../core/nada_theme.dart';
import '../data/nada_models.dart';
import '../state/nada_scope.dart';
import 'layout.dart';
import 'widgets/nada_widgets.dart';

/// The whole medal economy, on its own page so the home stays quiet.
class MedalsScreen extends StatelessWidget {
  const MedalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = NadaScope.of(context).stats;
    final earned = stats.medalsThisWeek;

    return NadaScreen(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NadaHeader(
            leading: NadaFootnote(
              label: 'Volver',
              onTap: () => Navigator.of(context).pop(),
            ),
            trailing: const NadaWordmark(),
          ),
          const SizedBox(height: 38),
          const NadaSectionLabel('Medallas'),
          const SizedBox(height: 16),
          Row(
            children: [
              NadaMedal(
                size: 64,
                filled: earned > 0,
                semanticLabel: earned == 0
                    ? 'sin medallas esta semana'
                    : '$earned medallas esta semana',
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        medalLabel(earned),
                        style: NadaType.title.copyWith(fontSize: 40),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'esta semana',
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
          const SizedBox(height: 22),
          Text(
            '${stats.medalsTotal} en total',
            style: NadaType.number.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 26),
          const NadaHairline(),
          const SizedBox(height: 22),
          Text(
            'una medalla por cada $nadaMinutesPerMedal minutos de nada. '
            'la semana empieza el lunes y el contador vuelve a cero, '
            'pero las que ya ganaste se quedan en tu colección.',
            style: NadaType.bodyMuted.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 22),
          const NadaHairline(),
          const SizedBox(height: 22),
          Text(
            'Te faltan ${stats.minutesToNextMedal} min para la siguiente.',
            style: NadaType.body.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'no sirven para nada. ese es el punto.',
            style: NadaType.italic.copyWith(
              fontSize: 18,
              color: NadaColors.faint,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
