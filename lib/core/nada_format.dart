/// Formatting that sounds human in Spanish, not like a log file.
library;

const _months = <String>[
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

const _weekdays = <String>[
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

String two(int n) => n.toString().padLeft(2, '0');

/// `08:14`
String clockTime(DateTime time) => '${two(time.hour)}:${two(time.minute)}';

/// `mm:ss` under an hour, `h:mm:ss` above it. This is what the hero shows.
String stopwatch(Duration duration) {
  final d = duration.isNegative ? Duration.zero : duration;
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);
  if (hours > 0) return '$hours:${two(minutes)}:${two(seconds)}';
  return '${two(minutes)}:${two(seconds)}';
}

/// `3 h 12 min`, `48 min`, `42 s`, `—`.
String compactDuration(Duration duration, {bool zeroAsDash = false}) {
  final d = duration.isNegative ? Duration.zero : duration;
  if (d == Duration.zero) return zeroAsDash ? '—' : '0 min';
  if (d.inSeconds < 60) return '${d.inSeconds} s';
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  if (minutes == 0) return '$hours h';
  return '$hours h $minutes min';
}

/// The line under the clock: `18 minutos y 42 segundos`.
String spokenDuration(Duration duration) {
  final d = duration.isNegative ? Duration.zero : duration;
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);

  String unit(int value, String singular, String plural) =>
      '$value ${value == 1 ? singular : plural}';

  if (hours > 0) {
    final tail = minutes > 0 ? ' y ${unit(minutes, 'minuto', 'minutos')}' : '';
    return '${unit(hours, 'hora', 'horas')}$tail';
  }
  if (minutes > 0) {
    final tail = seconds > 0
        ? ' y ${unit(seconds, 'segundo', 'segundos')}'
        : '';
    return '${unit(minutes, 'minuto', 'minutos')}$tail';
  }
  return unit(seconds, 'segundo', 'segundos');
}

/// `hoy`, `ayer`, `martes 21 de octubre`.
String relativeDay(DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(day.year, day.month, day.day);
  final difference = today.difference(target).inDays;

  if (difference == 0) return 'hoy';
  if (difference == 1) return 'ayer';
  if (difference < 7 && difference > 0) {
    return _weekdays[target.weekday - 1];
  }
  return '${_weekdays[target.weekday - 1]} ${target.day} de ${_months[target.month - 1]}';
}

/// `21 de octubre`
String longDate(DateTime date) =>
    '${date.day} de ${_months[date.month - 1]} de ${date.year}';

/// `viernes 23 de octubre`, the dateline at the top of the ledger.
String journalDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]} ${date.day} de ${_months[date.month - 1]}';

/// `racha de 4 días`, `racha de 1 día`, `sin racha`.
String streakLabel(int days) {
  if (days <= 0) return 'sin racha';
  if (days == 1) return 'racha de 1 día';
  return 'racha de $days días';
}

String sessionCountLabel(int count) {
  if (count == 0) return 'ninguna sesión';
  if (count == 1) return '1 sesión';
  return '$count sesiones';
}
