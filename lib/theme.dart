import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

/// Pismo sa serifima za naslove (kao na sajtu).
const String kSerif = 'serif';

/// Rezerva za pismo sa serifima: Android ima "serif", a iPhone ne, pa
/// tamo koristi Georgia / Times New Roman (da naslovi izgledaju isto).
const List<String> kSerifFallback = ['Georgia', 'Times New Roman', 'Noto Serif'];

/// Svetla / tamna tema (dugme sa suncem u zaglavlju).
/// Izbor se pamti u telefonu.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.light);
  static final ThemeController instance = ThemeController._();

  static const _key = 'tamna_tema';

  bool get isDark => value == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value = (prefs.getBool(_key) ?? false) ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    value = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isDark);
  }
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final ink = dark ? const Color(0xFFF1F1F3) : AppConfig.inkColor;
  final bg = dark ? const Color(0xFF0F0F12) : Colors.white;

  final scheme = ColorScheme.fromSeed(
    seedColor: AppConfig.brandColor,
    brightness: brightness,
  ).copyWith(
    primary: AppConfig.brandColor,
    onPrimary: Colors.white,
    surface: bg,
    onSurface: ink,
    onSurfaceVariant: dark ? const Color(0xFF9C9CA3) : const Color(0xFF9A9AA0),
    outlineVariant: dark ? const Color(0xFF2A2A30) : const Color(0xFFE7E7EA),
    surfaceContainerHighest:
        dark ? const Color(0xFF1D1D22) : const Color(0xFFF3F3F5),
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    dividerColor: scheme.outlineVariant,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppConfig.brandColor),
    snackBarTheme:
        const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Kratice za boje iz teme, da kod bude čitljiviji.
extension PvColors on BuildContext {
  /// Boja naslova i teksta.
  Color get ink => Theme.of(this).colorScheme.onSurface;

  /// Siva za "Autor", datum i sitne natpise.
  Color get muted => Theme.of(this).colorScheme.onSurfaceVariant;

  /// Tanke linije između vesti.
  Color get line => Theme.of(this).colorScheme.outlineVariant;

  /// Svetlosiva pozadina kutija (deljenje, pretraga).
  Color get box => Theme.of(this).colorScheme.surfaceContainerHighest;

  /// Pozadina ekrana.
  Color get bg => Theme.of(this).colorScheme.surface;
}

/// Veličina slova u tekstu vesti (dugmad A− i A+). Pamti se u telefonu.
class TextSizeController extends ValueNotifier<double> {
  TextSizeController._() : super(1.0);
  static final TextSizeController instance = TextSizeController._();

  static const _key = 'velicina_slova';
  static const double min = 0.8;
  static const double max = 1.5;
  static const double step = 0.1;

  bool get canShrink => value > min + 0.01;
  bool get canGrow => value < max - 0.01;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value = (prefs.getDouble(_key) ?? 1.0).clamp(min, max);
  }

  Future<void> change(double delta) async {
    value = double.parse((value + delta).clamp(min, max).toStringAsFixed(1));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, value);
  }
}
