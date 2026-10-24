import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nada_theme.dart';
import '../state/nada_scope.dart';
import 'home_view.dart';
import 'session_view.dart';
import 'summary_view.dart';
import 'widgets/nada_widgets.dart';

class NadaShell extends StatelessWidget {
  const NadaShell({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NadaScope.of(context);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 420);

    final Widget screen;
    if (!controller.ready) {
      screen = const _BootView(key: ValueKey('boot'));
    } else if (controller.hasActiveSession) {
      screen = const SessionView(key: ValueKey('session'));
    } else if (controller.lastFinished != null) {
      screen = const SummaryView(key: ValueKey('summary'));
    } else {
      screen = const HomeView(key: ValueKey('home'));
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: NadaTheme.overlay,
      child: Scaffold(
        backgroundColor: NadaColors.voidBlack,
        body: AnimatedSwitcher(
          duration: duration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (current, previous) =>
              Stack(fit: StackFit.expand, children: [...previous, ?current]),
          transitionBuilder: (child, animation) {
            if (reduceMotion) return child;
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.012),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: screen,
        ),
      ),
    );
  }
}

class _BootView extends StatelessWidget {
  const _BootView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Opacity(opacity: 0.5, child: NadaWordmark(fontSize: 22)),
    );
  }
}
