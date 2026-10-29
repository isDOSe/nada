import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nada_format.dart';
import '../core/nada_theme.dart';
import '../data/nada_models.dart';
import '../state/nada_scope.dart';
import 'layout.dart';
import 'widgets/nada_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _copied = false;
  Timer? _copiedTimer;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  Future<void> _copySummary(NadaStats stats) async {
    final text =
        'nada!\n'
        '${compactDuration(stats.total)} sin hacer nada\n'
        '${sessionCountLabel(stats.sessionCount)} · ${streakLabel(stats.streakDays)}';
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    if (!mounted) return;
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = NadaScope.of(context);
    final stats = controller.stats;
    final sessions = controller.sessions;

    final entries = _buildEntries(sessions);

    return NadaScreen(
      padding: EdgeInsets.zero,
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(26, 10, 26, 0),
            sliver: SliverToBoxAdapter(
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
                  const SizedBox(height: 38),
                  const NadaSectionLabel('registro'),
                  const SizedBox(height: 10),
                  Text(
                    compactDuration(stats.total, zeroAsDash: true),
                    style: NadaType.title.copyWith(
                      fontSize: 68,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${sessionCountLabel(stats.sessionCount)} · ${streakLabel(stats.streakDays)}',
                    style: NadaType.label.copyWith(fontSize: 16),
                  ),
                  if (sessions.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'desde el ${longDate(sessions.last.startedAt)}',
                      style: NadaType.label.copyWith(
                        fontSize: 16,
                        color: NadaColors.ash,
                      ),
                    ),
                    if (sessions.length > 1) ...[
                      const SizedBox(height: 4),
                      Text(
                        'la más larga ${compactDuration(stats.longest)} · promedio ${compactDuration(stats.average)}',
                        style: NadaType.label.copyWith(
                          fontSize: 16,
                          color: NadaColors.ash,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 14),
                  if (sessions.isNotEmpty)
                    NadaFootnote(
                      label: _copied ? 'copiado' : 'copiar resumen',
                      emphasize: _copied,
                      onTap: () => _copySummary(stats),
                    ),
                  const SizedBox(height: 26),
                  if (sessions.isNotEmpty) const NadaHairline(),
                ],
              ),
            ),
          ),
          if (sessions.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 10, 26, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'aquí todavía\nno hay nada.',
                      style: NadaType.title.copyWith(
                        fontSize: 46,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'empieza con un minuto y mira cómo se acumula.',
                      style: NadaType.italic,
                    ),
                    const Spacer(),
                    NadaButton(
                      label: 'empezar a no hacer nada',
                      onPressed: () {
                        controller.startSession();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 40),
              sliver: SliverList.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return switch (entry) {
                    _DayEntry() => _DayHeader(entry: entry),
                    _SessionEntry() => _SessionRow(
                      session: entry.session,
                      onTap: () => _showSession(context, entry.session),
                    ),
                  };
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showSession(BuildContext context, NadaSession session) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: NadaColors.voidBlack,
      barrierColor: const Color(0xB3000000),
      isScrollControlled: false,
      builder: (sheetContext) => _SessionSheet(session: session),
    );
  }

  List<_Entry> _buildEntries(List<NadaSession> sessions) {
    final entries = <_Entry>[];
    String? currentKey;
    final days = <String, List<NadaSession>>{};

    for (final session in sessions) {
      final key =
          '${session.startedAt.year}-${session.startedAt.month}-${session.startedAt.day}';
      days.putIfAbsent(key, () => []).add(session);
    }

    for (final group in days.entries) {
      if (group.key == currentKey) continue;
      currentKey = group.key;
      final daySessions = group.value;
      var total = Duration.zero;
      for (final session in daySessions) {
        total += session.duration;
      }
      entries.add(_DayEntry(day: daySessions.first.startedAt, total: total));
      for (final session in daySessions) {
        entries.add(_SessionEntry(session));
      }
    }
    return entries;
  }
}

sealed class _Entry {
  const _Entry();
}

class _DayEntry extends _Entry {
  const _DayEntry({required this.day, required this.total});
  final DateTime day;
  final Duration total;
}

class _SessionEntry extends _Entry {
  const _SessionEntry(this.session);
  final NadaSession session;
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.entry});

  final _DayEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 2),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                relativeDay(entry.day),
                style: const TextStyle(
                  fontFamily: NadaFonts.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: NadaColors.bone,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                compactDuration(entry.total),
                style: NadaType.label.copyWith(color: NadaColors.ash),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const NadaHairline(),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.onTap});

  final NadaSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final modeLabel = switch (session.mode) {
      NadaMode.free => 'sin límite',
      NadaMode.goal =>
        session.completed
            ? 'meta cumplida'
            : 'meta ${compactDuration(session.goal ?? Duration.zero)}',
    };

    return Semantics(
      button: true,
      label:
          '${compactDuration(session.duration)} de nada, ${relativeDay(session.startedAt)} a las ${clockTime(session.startedAt)}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: NadaColors.hairline)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                compactDuration(session.duration),
                style: NadaType.number.copyWith(fontSize: 28),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${clockTime(session.startedAt)} — ${clockTime(session.endedAt)}',
                    style: NadaType.label.copyWith(color: NadaColors.ash),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    modeLabel,
                    style: NadaType.label.copyWith(
                      color: NadaColors.ash,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionSheet extends StatelessWidget {
  const _SessionSheet({required this.session});

  final NadaSession session;

  Future<void> _confirmDelete(BuildContext context) async {
    final controller = NadaScope.read(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xCC000000),
      builder: (dialogContext) => Dialog(
        backgroundColor: NadaColors.voidBlack,
        insetPadding: const EdgeInsets.symmetric(horizontal: 26),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: NadaColors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'borrar esta sesión',
                style: NadaType.title.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 12),
              Text(
                'desaparecerá del registro. el tiempo ya lo perdiste igual.',
                style: NadaType.bodyMuted,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  NadaButton(
                    label: 'cancelar',
                    kind: NadaButtonKind.quiet,
                    expand: false,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                  const Spacer(),
                  NadaButton(
                    label: 'borrar',
                    kind: NadaButtonKind.quiet,
                    expand: false,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      controller.deleteSession(session.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = session.completed;
    final goal = session.goal;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NadaHairline(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NadaSectionLabel(
                    '${relativeDay(session.startedAt)} · ${clockTime(session.startedAt)} — ${clockTime(session.endedAt)}',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    compactDuration(session.duration),
                    style: NadaType.title.copyWith(
                      fontSize: 56,
                      letterSpacing: -1.5,
                    ),
                  ),
                  Text(
                    'de nada.',
                    style: NadaType.italic.copyWith(fontSize: 27, height: 1.1),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    goal == null
                        ? 'sin límite. contó hacia arriba hasta que decidiste parar.'
                        : completed
                        ? 'meta de ${compactDuration(goal)}. la cumpliste sin hacer nada.'
                        : 'meta de ${compactDuration(goal)}. la cortaste antes.',
                    style: NadaType.bodyMuted.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 24),
                  NadaFootnote(
                    label: 'borrar sesión',
                    onTap: () => _confirmDelete(context),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: NadaFootnote(
                      label: 'cerrar',
                      onTap: () => Navigator.of(context).pop(),
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
