import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The entire visual language of nada! lives here.
///
/// One ink, one void, two serifs. No accent colours, no shadows, no
/// rounded corners. Anything that does not carry information is removed.
abstract final class NadaColors {
  static const Color voidBlack = Color(0xFF000000);
  static const Color bone = Color(0xFFF2EFE6);
  static const Color ash = Color(0xFFA6A096);
  static const Color faint = Color(0xFF8B857A);
  static const Color hairline = Color(0xFF26231F);
  static const Color edge = Color(0xFF4A453D);
  static const Color relief = Color(0xFF6E675C);
  static const Color pressed = Color(0xFF131210);
}

abstract final class NadaFonts {
  static const String display = 'InstrumentSerif';
  static const String text = 'CrimsonText';
}

abstract final class NadaType {
  static const TextStyle hero = TextStyle(
    fontFamily: NadaFonts.display,
    fontSize: 132,
    height: 0.86,
    letterSpacing: -4,
    color: NadaColors.bone,
  );

  static const TextStyle clock = TextStyle(
    fontFamily: NadaFonts.display,
    fontSize: 96,
    height: 0.95,
    letterSpacing: -1,
    color: NadaColors.bone,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle title = TextStyle(
    fontFamily: NadaFonts.display,
    fontSize: 42,
    height: 1.02,
    letterSpacing: -0.8,
    color: NadaColors.bone,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: NadaFonts.display,
    fontSize: 32,
    height: 1.1,
    color: NadaColors.bone,
  );

  static const TextStyle body = TextStyle(
    fontFamily: NadaFonts.text,
    fontSize: 18,
    height: 1.5,
    color: NadaColors.bone,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamily: NadaFonts.text,
    fontSize: 17,
    height: 1.5,
    color: NadaColors.ash,
  );

  static const TextStyle italic = TextStyle(
    fontFamily: NadaFonts.text,
    fontStyle: FontStyle.italic,
    fontSize: 20,
    height: 1.42,
    color: NadaColors.ash,
  );

  static const TextStyle label = TextStyle(
    fontFamily: NadaFonts.text,
    fontSize: 16,
    height: 1.4,
    letterSpacing: 0.1,
    color: NadaColors.ash,
  );

  static const TextStyle button = TextStyle(
    fontFamily: NadaFonts.text,
    fontSize: 19,
    height: 1.2,
    letterSpacing: 0.1,
    color: NadaColors.bone,
  );

  static const TextStyle number = TextStyle(
    fontFamily: NadaFonts.display,
    fontSize: 32,
    height: 1.0,
    letterSpacing: -0.4,
    color: NadaColors.bone,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

abstract final class NadaTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: NadaColors.bone,
      onPrimary: NadaColors.voidBlack,
      secondary: NadaColors.ash,
      surface: NadaColors.voidBlack,
      onSurface: NadaColors.bone,
      error: Color(0xFFD9A3A3),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: NadaColors.voidBlack,
      canvasColor: NadaColors.voidBlack,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      fontFamily: NadaFonts.text,
      textTheme: const TextTheme(
        displayLarge: NadaType.hero,
        displayMedium: NadaType.title,
        headlineSmall: NadaType.sectionTitle,
        bodyLarge: NadaType.body,
        bodyMedium: NadaType.bodyMuted,
        labelLarge: NadaType.button,
        labelSmall: NadaType.label,
      ),
      dividerTheme: const DividerThemeData(
        color: NadaColors.hairline,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: NadaColors.voidBlack,
        modalBackgroundColor: NadaColors.voidBlack,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(),
        showDragHandle: false,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: NadaColors.voidBlack,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: NadaColors.bone,
        selectionColor: Color(0x33F2EFE6),
        selectionHandleColor: NadaColors.bone,
      ),
    );
  }

  static const SystemUiOverlayStyle overlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: NadaColors.voidBlack,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  );
}
