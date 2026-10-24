import 'package:flutter/material.dart';

import 'core/nada_theme.dart';
import 'data/session_repository.dart';
import 'services/nada_notifications.dart';
import 'state/nada_controller.dart';
import 'state/nada_scope.dart';
import 'ui/nada_shell.dart';

class NadaApp extends StatefulWidget {
  const NadaApp({super.key, this.repository, this.notifications});

  /// Injection points for tests and for the future premium build.
  final SessionRepository? repository;
  final SessionNotifications? notifications;

  @override
  State<NadaApp> createState() => _NadaAppState();
}

class _NadaAppState extends State<NadaApp> with WidgetsBindingObserver {
  late final NadaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NadaController(
      repository: widget.repository ?? LocalSessionRepository(),
      notifications: widget.notifications,
    );
    WidgetsBinding.instance.addObserver(this);
    _controller.init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _controller.handleAppPaused();
      case AppLifecycleState.resumed:
        _controller.handleAppResumed();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NadaScope(
      controller: _controller,
      child: MaterialApp(
        title: 'nada!',
        debugShowCheckedModeBanner: false,
        theme: NadaTheme.dark,
        themeMode: ThemeMode.dark,
        home: const NadaShell(),
      ),
    );
  }
}
