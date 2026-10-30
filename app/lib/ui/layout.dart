import 'package:flutter/material.dart';

import '../core/nada_theme.dart';
import 'widgets/nada_widgets.dart';

/// Every screen shares the same quiet frame: 26dp margins, a wordmark, and
/// as much air as the content can survive.
class NadaScreen extends StatelessWidget {
  const NadaScreen({
    super.key,
    required this.child,
    this.scrollable = false,
    this.padding = const EdgeInsets.fromLTRB(26, 10, 26, 16),
  });

  final Widget child;
  final bool scrollable;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return SafeArea(
      child: scrollable
          ? SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: content,
            )
          : content,
    );
  }
}

class NadaHeader extends StatelessWidget {
  const NadaHeader({super.key, this.trailing, this.leading});

  final Widget? trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          leading ?? const NadaWordmark(),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              // Two text buttons on a narrow screen (or with large text) must
              // shrink instead of overflowing the header.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: trailing ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NadaSectionLabel extends StatelessWidget {
  const NadaSectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: NadaType.label.copyWith(color: color ?? NadaColors.ash),
    );
  }
}

/// A full-width hairline row used for footer links and secondary actions.
class NadaFooterRow extends StatelessWidget {
  const NadaFooterRow({super.key, required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [left, right],
    );
  }
}

Route<T> nadaRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    // A Material ancestor is not optional: without it Flutter falls back to
    // the yellow-underlined debug text style. The home route gets one from
    // Scaffold; pushed routes need their own.
    pageBuilder: (_, _, _) =>
        Material(color: NadaColors.voidBlack, child: page),
    transitionsBuilder: (context, animation, secondary, child) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        return child;
      }
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.018),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
