import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_info.dart';
import '../core/nada_theme.dart';
import '../data/nada_models.dart';
import '../state/nada_scope.dart';
import 'layout.dart';
import 'manifesto_screen.dart';
import 'widgets/nada_widgets.dart';

Future<void> showNadaSettings(BuildContext context) {
  final controller = NadaScope.read(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: NadaColors.voidBlack,
    barrierColor: const Color(0xB3000000),
    builder: (_) => _SettingsSheet(initialSettings: controller.settings),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({required this.initialSettings});

  final NadaSettings initialSettings;

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool _asking = false;
  String? _widgetMessage;
  late final List<int> _times;
  late final List<TextEditingController> _timeControllers;

  @override
  void initState() {
    super.initState();
    _times = [...widget.initialSettings.quickMinutes];
    _timeControllers = [
      for (final minutes in _times) TextEditingController(text: '$minutes'),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await NadaScope.read(context).refreshNotificationPermission();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    for (final controller in _timeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _commitTime(int index, int value) {
    final minutes = value.clamp(1, 999);
    _times[index] = minutes;
    final controller = _timeControllers[index];
    final text = '$minutes';
    if (controller.text != text) {
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    NadaScope.read(context).updateQuickMinute(index, minutes);
  }

  void _onTimeChanged(int index, String raw) {
    final value = int.tryParse(raw);
    if (value == null || value < 1 || value > 999) return;
    _times[index] = value;
    NadaScope.read(context).updateQuickMinute(index, value);
  }

  void _normalizeTime(int index) {
    final value = int.tryParse(_timeControllers[index].text);
    if (value == null || value < 1 || value > 999) {
      _timeControllers[index].text = '${_times[index]}';
      return;
    }
    _commitTime(index, value);
  }

  void _stepTime(int index, int delta) {
    final current = int.tryParse(_timeControllers[index].text) ?? _times[index];
    _commitTime(index, (current + delta).clamp(1, 999));
  }

  Widget _timeRow(int index) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: TextField(
            controller: _timeControllers[index],
            keyboardType: TextInputType.number,
            keyboardAppearance: Brightness.dark,
            textAlign: TextAlign.center,
            style: NadaType.number.copyWith(fontSize: 24),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            onChanged: (value) => _onTimeChanged(index, value),
            onSubmitted: (_) => _normalizeTime(index),
            onTapOutside: (_) => _normalizeTime(index),
            decoration: const InputDecoration(
              isDense: true,
              counterText: '',
              contentPadding: EdgeInsets.symmetric(vertical: 9, horizontal: 6),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: NadaColors.edge),
                borderRadius: BorderRadius.zero,
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: NadaColors.bone),
                borderRadius: BorderRadius.zero,
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: NadaColors.edge),
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('min', style: NadaType.label.copyWith(color: NadaColors.ash)),
        const Spacer(),
        _StepButton(
          label: '−',
          semantic: 'Restar cinco minutos',
          onTap: () => _stepTime(index, -5),
        ),
        const SizedBox(width: 8),
        _StepButton(
          label: '+',
          semantic: 'Sumar cinco minutos',
          onTap: () => _stepTime(index, 5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = NadaScope.of(context);
    final settings = controller.settings;
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NadaHairline(),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(26, 22, 26, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ajustes',
                          style: NadaType.title.copyWith(fontSize: 36),
                        ),
                        const Spacer(),
                        NadaFootnote(
                          label: 'listo',
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const NadaSectionLabel('tiempos rápidos'),
                    const SizedBox(height: 8),
                    Text(
                      'los tres tiempos de la pantalla principal. edítalos a tu gusto.',
                      style: NadaType.label.copyWith(
                        fontSize: 16,
                        color: NadaColors.ash,
                      ),
                    ),
                    const SizedBox(height: 18),
                    for (var index = 0; index < _times.length; index++) ...[
                      _timeRow(index),
                      if (index < _times.length - 1) const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 28),
                    const NadaHairline(),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'notificación permanente',
                                style: NadaType.body.copyWith(fontSize: 18),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'el tiempo en curso, siempre visible.',
                                style: NadaType.label.copyWith(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: NadaToggle(
                            value: settings.notifications,
                            label: 'Notificación permanente',
                            onChanged: (value) => controller.updateSettings(
                              settings.copyWith(notifications: value),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (android && settings.notifications) ...[
                      const SizedBox(height: 10),
                      if (!controller.notificationsGranted)
                        NadaFootnote(
                          label: _asking
                              ? 'pidiendo permiso...'
                              : 'permitir notificaciones',
                          onTap: _asking
                              ? () {}
                              : () async {
                                  setState(() => _asking = true);
                                  final granted = await controller
                                      .requestNotificationPermission();
                                  if (!granted) {
                                    await controller.openNotificationSettings();
                                  }
                                  if (mounted) setState(() => _asking = false);
                                },
                        )
                      else
                        Text(
                          'permiso concedido.',
                          style: NadaType.label.copyWith(
                            fontSize: 16,
                            color: NadaColors.ash,
                          ),
                        ),
                    ],
                    if (android) ...[
                      const SizedBox(height: 22),
                      const NadaHairline(),
                      const SizedBox(height: 20),
                      Text(
                        'widget de inicio',
                        style: NadaType.body.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '2×2 en tu pantalla de inicio. muestra tu nada acumulada.',
                        style: NadaType.label.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        children: [
                          NadaChoice(
                            label: 'negro',
                            selected:
                                settings.widgetTheme == NadaWidgetTheme.dark,
                            onTap: () => controller.updateSettings(
                              settings.copyWith(
                                widgetTheme: NadaWidgetTheme.dark,
                              ),
                            ),
                          ),
                          NadaChoice(
                            label: 'blanco',
                            selected:
                                settings.widgetTheme == NadaWidgetTheme.light,
                            onTap: () => controller.updateSettings(
                              settings.copyWith(
                                widgetTheme: NadaWidgetTheme.light,
                              ),
                            ),
                          ),
                        ],
                      ),
                      NadaFootnote(
                        label: 'añadir widget',
                        onTap: () async {
                          final pinned = await controller.requestWidgetPin();
                          if (!mounted) return;
                          setState(() {
                            _widgetMessage = pinned
                                ? null
                                : 'tu launcher no permite añadirlo desde aquí. búscalo en el menú de widgets.';
                          });
                        },
                      ),
                      if (_widgetMessage != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _widgetMessage!,
                          style: NadaType.label.copyWith(
                            fontSize: 15,
                            color: NadaColors.ash,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                    const NadaHairline(),
                    const SizedBox(height: 8),
                    NadaFootnote(
                      label: 'la filosofía del vacío',
                      expand: true,
                      onTap: () {
                        final navigator = Navigator.of(
                          context,
                          rootNavigator: true,
                        );
                        final host = navigator.context;
                        navigator.pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!host.mounted) return;
                          Navigator.of(
                            host,
                          ).push(nadaRoute(const ManifestoScreen()));
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    NadaFootnote(
                      label: 'acerca de nada!',
                      expand: true,
                      onTap: () {
                        final navigator = Navigator.of(
                          context,
                          rootNavigator: true,
                        );
                        final host = navigator.context;
                        navigator.pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!host.mounted) return;
                          showAboutNada(host);
                        });
                      },
                    ),
                    const SizedBox(height: 22),
                    const NadaHairline(),
                    const SizedBox(height: 14),
                    Text(
                      'todo se queda aquí. nada viaja a ningún lado.',
                      style: NadaType.label.copyWith(
                        fontSize: 16,
                        color: NadaColors.ash,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'versión $nadaVersion · sin cuentas, sin nube, sin prisa',
                      style: NadaType.label.copyWith(
                        fontSize: 15,
                        color: NadaColors.faint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showAboutNada(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: NadaColors.voidBlack,
    barrierColor: const Color(0xB3000000),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NadaHairline(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NadaWordmark(fontSize: 30),
                  const SizedBox(height: 14),
                  Text(
                    'el tiempo que no le debes a nadie.',
                    style: NadaType.italic.copyWith(fontSize: 21),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'sin cuentas. sin anuncios. sin nube. todo se queda en este teléfono.',
                    style: NadaType.bodyMuted.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'hecho con flutter, instrument serif y crimson text.',
                    style: NadaType.label,
                  ),
                  Text(
                    'ernesto flames (dose) · licencia mit',
                    style: NadaType.label,
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: NadaFootnote(
                      label: 'cerrar',
                      onTap: () => Navigator.of(sheetContext).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.semantic,
    required this.onTap,
  });

  final String label;
  final String semantic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(border: Border.all(color: NadaColors.edge)),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: NadaFonts.display,
                fontSize: 24,
                height: 1,
                color: NadaColors.bone,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
