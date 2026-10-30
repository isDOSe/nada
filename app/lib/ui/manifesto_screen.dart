import 'package:flutter/material.dart';

import '../core/nada_theme.dart';
import 'layout.dart';
import 'widgets/nada_widgets.dart';

class ManifestoScreen extends StatelessWidget {
  const ManifestoScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 44),
          Text(
            'el arte de\nno hacer nada',
            style: NadaType.title.copyWith(fontSize: 56, height: 0.98),
          ),
          const SizedBox(height: 32),
          Text(
            'La app para hacer... nada. O algo. Depende.',
            style: NadaType.italic.copyWith(
              fontSize: 23,
              height: 1.45,
              color: NadaColors.bone,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '*despliega pergamino místico*',
            style: NadaType.italic.copyWith(
              fontSize: 17,
              color: NadaColors.faint,
            ),
          ),
          const SizedBox(height: 26),
          const NadaHairline(),
          const SizedBox(height: 30),
          const _Paragraph(
            'Esto es un contador. Pones un número, presionas iniciar y esperas. No hay ranking, no hay coach gritándote en mayúsculas y no hay una versión premium que te venda la paz interior.',
          ),
          const _Paragraph(
            'Pero cuando te sientas a no hacer nada durante 25 minutos, ¿qué estás haciendo en realidad?',
          ),
          const _Paragraph(
            'Estás ignorando 47 notificaciones. Resistiendo las ganas de mirar el teléfono. Sentado. Respirando. Existiendo. Practicando el arte perdido de estar sin justificarte.',
          ),
          const _Quote(
            '«La tensión más extrema no es hacer algo. Es hacer algo mientras finges que no haces nada.» — alguien, probablemente en LinkedIn',
          ),
          const _Paragraph(
            'Diógenes vivía en un barril. Nadie le dijo que tenía que ser productivo. Y aun así la filosofía lo recuerda. Tú no necesitas un barril: necesitas 25 minutos y la valentía de no llenarlos.',
          ),
          const _Paragraph(
            'No hacer nada es hacer algo. Es contradecirte. Es la paradoja del vacío productivo. Es el yin y el yang de existir sin esforzarse.',
          ),
          const _Paragraph(
            'Así que la próxima vez que alguien te pregunte qué haces, míralo a los ojos y di: «Nada. Literalmente nada. Estoy corriendo un temporizador.»',
          ),
          const SizedBox(height: 18),
          Text(
            'Y ahora que has leído todo esto... ¿cuánto tiempo acabas de perder que pudiste haber pasado haciendo absolutamente nada?',
            style: NadaType.body.copyWith(
              fontSize: 21,
              height: 1.55,
              color: NadaColors.bone,
            ),
          ),
          const SizedBox(height: 34),
          Text(
            '— nada!',
            style: NadaType.italic.copyWith(color: NadaColors.faint),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        text,
        style: NadaType.body.copyWith(
          fontSize: 20,
          height: 1.6,
          color: NadaColors.ash,
        ),
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 26),
      padding: const EdgeInsets.only(left: 20),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: NadaColors.bone, width: 1)),
      ),
      child: Text(
        text,
        style: NadaType.italic.copyWith(
          fontSize: 24,
          height: 1.42,
          color: NadaColors.bone,
        ),
      ),
    );
  }
}
