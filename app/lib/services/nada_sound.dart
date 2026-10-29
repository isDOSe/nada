import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The short chime that closes a session.
abstract interface class EndSound {
  Future<void> play();
}

class AndroidEndSound implements EndSound {
  static const MethodChannel _channel = MethodChannel('nada/sound');

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> play() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('play');
    } catch (_) {
      // Sound is a courtesy; never let it break a session closure.
    }
  }
}

class NoopEndSound implements EndSound {
  const NoopEndSound();

  @override
  Future<void> play() async {}
}
