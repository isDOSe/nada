import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nada_format.dart';
import '../core/nada_theme.dart';
import '../state/nada_scope.dart';
import 'layout.dart';
import 'widgets/nada_aurora.dart';
import 'widgets/nada_widgets.dart';

class SessionView extends StatelessWidget {
  const SessionView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NadaScope.of(context);
    final goal = controller.activeGoal;
    final startedAt = controller.activeStartedAt ?? DateTime.now();
    final running = controller.isRunning;

    return Stack(
      fit: StackFit.expand,
      children: [
        NadaAurora(active: running),
        NadaScreen(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NadaHeader(
                trailing: running
                    ? null
                    : Text(
                        'en pausa',
                        style: NadaType.label.copyWith(
                          fontSize: 16,
                          color: NadaColors.ash,
                        ),
                      ),
              ),
              Expanded(
                child: ValueListenableBuilder<Duration>(
                  valueListenable: controller.elapsed,
                  builder: (context, elapsed, _) {
                    final progress = goal == null
                        ? 0.0
                        : (elapsed.inMilliseconds / goal.inMilliseconds).clamp(
                            0.0,
                            1.0,
                          );
                    final remaining = goal == null
                        ? Duration.zero
                        : (goal - elapsed).isNegative
                        ? Duration.zero
                        : goal - elapsed;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NadaClock(
                          value: elapsed,
                          text: stopwatch(elapsed),
                          size: 96,
                          color: running ? NadaColors.bone : NadaColors.ash,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          running
                              ? (elapsed.inSeconds < 2
                                    ? 'acabas de dejar de hacer algo'
                                    : 'llevas ${spokenDuration(elapsed)} sin hacer nada')
                              : 'el vacío se quedó quieto.',
                          style: NadaType.italic.copyWith(fontSize: 21),
                        ),
                        if (goal == null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'sin límite · desde las ${clockTime(startedAt)}',
                            style: NadaType.label.copyWith(
                              fontSize: 16,
                              color: NadaColors.ash,
                            ),
                          ),
                        ],
                        if (goal != null) ...[
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Text(
                                'meta de ${compactDuration(goal)}',
                                style: NadaType.label.copyWith(fontSize: 16),
                              ),
                              const Spacer(),
                              Text(
                                'quedan ${stopwatch(remaining)}',
                                style: NadaType.label.copyWith(
                                  fontSize: 16,
                                  color: running
                                      ? NadaColors.bone
                                      : NadaColors.ash,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) => Stack(
                              children: [
                                Container(
                                  height: 1,
                                  width: constraints.maxWidth,
                                  color: NadaColors.hairline,
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 700),
                                  curve: Curves.linear,
                                  height: 1,
                                  width: constraints.maxWidth * progress,
                                  color: running
                                      ? NadaColors.bone
                                      : NadaColors.ash,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              NadaButton(
                label: running ? 'pausar' : 'continuar',
                depressed: !running,
                semanticLabel: running
                    ? 'Pausar esta sesión de nada'
                    : 'Continuar esta sesión de nada',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  if (running) {
                    controller.pauseSession();
                  } else {
                    controller.resumeSession();
                  }
                },
              ),
              const SizedBox(height: 18),
              Center(
                child: NadaButton(
                  label: 'terminar',
                  kind: NadaButtonKind.quiet,
                  expand: false,
                  semanticLabel: 'Terminar y guardar esta sesión',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    controller.finishSession();
                  },
                ),
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ],
    );
  }
}
