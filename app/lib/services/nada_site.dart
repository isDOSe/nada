import 'package:flutter/services.dart';

/// Opens the web version in the system browser.
///
/// The app itself keeps its no-internet promise: the page is loaded by the
/// browser, not by this process.
abstract final class NadaSite {
  static const MethodChannel _channel = MethodChannel('nada/site');

  static Future<bool> open() async {
    try {
      final opened = await _channel.invokeMethod<bool>('open');
      return opened ?? false;
    } catch (_) {
      return false;
    }
  }
}
