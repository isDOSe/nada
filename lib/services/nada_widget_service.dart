import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/nada_format.dart';
import '../data/nada_models.dart';

/// Contract used by the controller. Tests can inject the no-op version so
/// they never touch the Android channel.
abstract interface class WidgetService {
  Future<void> update({
    required NadaStats stats,
    required NadaWidgetTheme theme,
  });

  Future<bool> requestPin();
}

class AndroidWidgetService implements WidgetService {
  static const MethodChannel _channel = MethodChannel('nada/widget');

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> update({
    required NadaStats stats,
    required NadaWidgetTheme theme,
  }) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('update', {
        'time': compactDuration(stats.total),
        'sessions': stats.sessionCount,
        'theme': theme.name,
      });
    } catch (_) {
      // A widget is optional; never interrupt a session for it.
    }
  }

  @override
  Future<bool> requestPin() async {
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>('pin') ?? false;
    } catch (_) {
      return false;
    }
  }
}

class NoopWidgetService implements WidgetService {
  const NoopWidgetService();

  @override
  Future<void> update({
    required NadaStats stats,
    required NadaWidgetTheme theme,
  }) async {}

  @override
  Future<bool> requestPin() async => false;
}
