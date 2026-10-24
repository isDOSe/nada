import 'package:flutter/widgets.dart';

import 'nada_controller.dart';

/// One controller, available to every route without a dependency package.
class NadaScope extends InheritedNotifier<NadaController> {
  const NadaScope({
    super.key,
    required NadaController controller,
    required super.child,
  }) : super(notifier: controller);

  static NadaController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NadaScope>();
    assert(scope != null, 'NadaScope is missing from the widget tree.');
    return scope!.notifier!;
  }

  /// Read without subscribing to rebuilds.
  static NadaController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<NadaScope>();
    assert(scope != null, 'NadaScope is missing from the widget tree.');
    return scope!.notifier!;
  }
}
