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
              label: 'volver',
              onTap: () => Navigator.of(context).pop(),
            ),
            trailing: const NadaWordmark(),
          ),
          const SizedBox(height: 44),
          Text(
            'la filosofía\ndel vacío',
            style: NadaType.title.copyWith(fontSize: 56, height: 0.98),
          ),
          const SizedBox(height: 32),
          Text(
            'No hacer nada no es un error del día.\nEs la parte del día que no le debes a nadie.',
            style: NadaType.italic.copyWith(
              fontSize: 23,
              height: 1.45,
              color: NadaColors.bone,
            ),
          ),
          const SizedBox(height: 30),
          const NadaHairline(),
          const SizedBox(height: 30),
          const _Paragraph(
            'Nos enseñaron a medir el tiempo por lo que producimos. Cada minuto tiene que justificarse: aprender algo, resolver algo, optimizar algo. Hasta descansar se volvió una tarea pendiente.',
          ),
          const _Paragraph(
            'La app propone lo contrario. Un contador que no te pide una meta, ni una racha, ni una identidad. Solo mide el rato en el que no le rendiste cuentas a nadie.',
          ),
          const _Quote(
            'La productividad te mide por lo que produces. Esto te mide por lo que te permites.',
          ),
          const _Paragraph(
            'Un minuto sin hacer nada no se recupera. Se gasta. Y está bien. No todo lo que cuenta se puede contar, pero este aparato lo intenta de todos modos.',
          ),
          const _Paragraph(
            'Diógenes vivía en un barril y no por eso dejó de ser recordado. Tú no necesitas un barril. Necesitas veinticinco minutos y la valentía de no llenarlos.',
          ),
          const SizedBox(height: 18),
          Text(
            'empieza. o no. el contador está aquí para cuando decidas que el vacío también merece un registro.',
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
