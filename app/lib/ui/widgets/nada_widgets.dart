import 'package:flutter/material.dart';

import '../../core/nada_theme.dart';

/// The wordmark. The period is the only grey thing in it, because the period
/// is where the nothing begins.
class NadaWordmark extends StatelessWidget {
  const NadaWordmark({super.key, this.fontSize = 20});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'nada!',
      header: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'nada',
              style: TextStyle(
                fontFamily: NadaFonts.text,
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
                letterSpacing: 0.2,
                color: NadaColors.bone,
                height: 1,
              ),
            ),
            TextSpan(
              text: '!',
              style: TextStyle(
                fontFamily: NadaFonts.text,
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
                color: NadaColors.ash,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum NadaButtonKind { solid, outline, quiet }

class NadaButton extends StatefulWidget {
  const NadaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = NadaButtonKind.solid,
    this.expand = true,
    this.semanticLabel,
    this.depressed = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final NadaButtonKind kind;
  final bool expand;
  final String? semanticLabel;

  /// Keeps a solid button visually sunken at rest. Used while a session is
  /// paused, so the button itself communicates the state.
  final bool depressed;

  @override
  State<NadaButton> createState() => _NadaButtonState();
}

class _NadaButtonState extends State<NadaButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isSolid = widget.kind == NadaButtonKind.solid;
    final isQuiet = widget.kind == NadaButtonKind.quiet;
    final isDown = isSolid && (_pressed || widget.depressed);

    final foreground = isSolid ? NadaColors.voidBlack : NadaColors.bone;
    final background = isSolid
        ? (_pressed ? NadaColors.ash : NadaColors.bone)
        : (_pressed ? NadaColors.pressed : Colors.transparent);
    final borderColor = isSolid
        ? (isDown ? NadaColors.edge : Colors.transparent)
        : (_pressed ? NadaColors.ash : NadaColors.edge);

    final content = Padding(
      padding: isQuiet
          ? const EdgeInsets.symmetric(vertical: 12, horizontal: 16)
          : const EdgeInsets.symmetric(vertical: 21, horizontal: 22),
      child: Text(
        widget.label,
        textAlign: TextAlign.center,
        style: NadaType.button.copyWith(
          color: _enabled ? foreground : NadaColors.faint,
          fontSize: isQuiet ? 18 : 23,
          fontWeight: isSolid ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel ?? widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          offset: isDown ? const Offset(0, 0.06) : Offset.zero,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            width: widget.expand ? double.infinity : null,
            decoration: BoxDecoration(
              color: background,
              border: Border.all(color: borderColor, width: 1),
              boxShadow: isSolid && _enabled && !isDown
                  ? [
                      BoxShadow(
                        color: NadaColors.relief,
                        offset: const Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// A duration choice: plain text, with an underline when selected.
///
/// Deliberately not a boxed button. The duration is a reading choice; the
/// actions around it are the buttons.
class NadaChoice extends StatelessWidget {
  const NadaChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.detail,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Optional second line, e.g. the editable minutes under a preset name.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(right: 20, top: 8, bottom: 12),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 160),
                  style: TextStyle(
                    fontFamily: NadaFonts.text,
                    fontSize: 18,
                    height: 1.2,
                    color: selected ? NadaColors.bone : NadaColors.ash,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  child: Text(label),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    detail!,
                    style: NadaType.label.copyWith(
                      fontSize: 14,
                      height: 1.2,
                      color: selected ? NadaColors.bone : NadaColors.faint,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 2,
                  color: selected ? NadaColors.bone : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NadaToggle extends StatelessWidget {
  const NadaToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: value ? NadaColors.bone : Colors.transparent,
            border: Border.all(
              color: value ? NadaColors.bone : NadaColors.faint,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              color: value ? NadaColors.voidBlack : NadaColors.ash,
            ),
          ),
        ),
      ),
    );
  }
}

/// Instrument Serif has beautiful but proportional figures. To keep a ticking
/// clock from shivering, every digit sits in a measured slot.
class NadaClock extends StatelessWidget {
  const NadaClock({
    super.key,
    required this.value,
    required this.text,
    this.size = 92,
    this.color = NadaColors.bone,
  });

  final Duration value;
  final String text;
  final double size;
  final Color color;

  static final Map<int, double> _digitWidthCache = {};

  double _digitWidth() {
    final key = size.round();
    final cached = _digitWidthCache[key];
    if (cached != null) return cached;
    final painter = TextPainter(
      text: TextSpan(
        text: '0',
        style: TextStyle(
          fontFamily: NadaFonts.display,
          fontSize: size,
          height: 0.92,
          letterSpacing: -1.5,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width;
    painter.dispose();
    _digitWidthCache[key] = width;
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final digitWidth = _digitWidth();
    final colonWidth = digitWidth * 0.46;
    final style = TextStyle(
      fontFamily: NadaFonts.display,
      fontSize: size,
      height: 0.92,
      letterSpacing: -1.5,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final children = <Widget>[];
    for (final character in text.split('')) {
      final isColon = character == ':';
      children.add(
        SizedBox(
          width: isColon ? colonWidth : digitWidth,
          child: Center(
            child: Text(character, style: style, maxLines: 1, softWrap: false),
          ),
        ),
      );
    }

    return Semantics(
      label: spokenSemantic(value),
      excludeSemantics: true,
      child: SizedBox(
        height: size * 0.98,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }

  static String spokenSemantic(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) return '$hours horas, $minutes minutos y $seconds segundos';
    return '$minutes minutos y $seconds segundos';
  }
}

class NadaHairline extends StatelessWidget {
  const NadaHairline({super.key, this.color = NadaColors.hairline});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: color, width: double.infinity);
}

/// A compact square button for navigation and secondary actions.
///
/// It used to be an underlined link; now every one of these is visibly a
/// button. The name stayed so call sites did not have to change.
class NadaFootnote extends StatefulWidget {
  const NadaFootnote({
    super.key,
    required this.label,
    required this.onTap,
    this.emphasize = false,
    this.expand = false,
    this.plain = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasize;
  final bool expand;

  /// Text only, no box. Used for the "registro" link on the home header.
  final bool plain;

  @override
  State<NadaFootnote> createState() => _NadaFootnoteState();
}

class _NadaFootnoteState extends State<NadaFootnote> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.emphasize;
    final plain = widget.plain;
    final borderColor = plain
        ? Colors.transparent
        : (_pressed
              ? NadaColors.ash
              : (active ? NadaColors.bone : NadaColors.edge));
    final textColor = _pressed
        ? NadaColors.bone
        : (active ? NadaColors.bone : NadaColors.ash);

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.expand ? double.infinity : null,
          padding: plain
              ? const EdgeInsets.symmetric(horizontal: 2, vertical: 10)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: plain
                ? Colors.transparent
                : (_pressed ? NadaColors.pressed : Colors.transparent),
            border: plain ? null : Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            widget.label,
            textAlign: widget.expand ? TextAlign.left : TextAlign.center,
            style: TextStyle(
              fontFamily: NadaFonts.text,
              fontSize: 16,
              height: 1.2,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// A small stamped "n!" for the weekly medal counter. Square, inverted when
/// earned, outlined when it is still a promise.
class NadaMedal extends StatelessWidget {
  const NadaMedal({
    super.key,
    this.size = 38,
    this.filled = false,
    this.semanticLabel,
  });

  final double size;
  final bool filled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? 'medalla de nada',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? NadaColors.bone : Colors.transparent,
          border: Border.all(
            color: filled ? NadaColors.bone : NadaColors.edge,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'n!',
            style: TextStyle(
              fontFamily: NadaFonts.display,
              fontStyle: FontStyle.italic,
              fontSize: size * 0.5,
              height: 1,
              letterSpacing: -0.5,
              color: filled ? NadaColors.voidBlack : NadaColors.ash,
            ),
          ),
        ),
      ),
    );
  }
}
