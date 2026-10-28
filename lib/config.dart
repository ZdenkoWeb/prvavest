import 'package:flutter/material.dart';

/// Osnovna podešavanja aplikacije. Ako nešto menjaš na sajtu
/// (boje, kategorije, tekst o sajtu), dovoljno je da promeniš ovde.
class AppConfig {
  static const String appName = 'Prva Vest';
  static const String siteUrl = 'https://prvavest.com';
  static const String apiBase = '$siteUrl/wp-json/wp/v2';

  /// Narandžasta boja sajta (traka NAJNOVIJE, dugmad, oznake).
  static const Color brandColor = Color(0xFFF26A1F);

  /// Tamnija narandžasta (levi deo trake NAJNOVIJE).
  static const Color brandDark = Color(0xFFD9541A);

  /// Narandžasta za sitan tekst, da bude čitljiviji.
  static const Color brandTextColor = Color(0xFFE05A14);

  /// Tamnoplava boja naslova, kao na sajtu.
  static const Color inkColor = Color(0xFF141938);

  /// Kategorija koja se ističe narandžastim okvirom na početku trake.
  static const String highlightedSlug = 'kolumna';

  /// Natpis na tom narandžastom dugmetu.
  static const String highlightedLabel = '#Kolumne';

  /// Kategorije u traci ispod logoa, tim redosledom (kao na sajtu).
  /// Ovo su "slug"-ovi kategorija (deo adrese posle /kategorija/).
  static const List<String> categorySlugs = [
    'kolumna',
    'srbija',
    'drustvo',
    'politika',
    'ekonomija',
    'svet',
    'sport',
    'hronika',
    'beograd',
    'tehnologija',
    'izbori-2026',
    'recepti',
  ];

  /// Tekst o sajtu u dnu ekrana Kategorije.
  static const String aboutText =
      'Prva Vest je digitalni medij posvećen najvažnijim vestima iz Srbije, '
      'regiona i sveta. Donosimo aktuelne vesti, zanimljive priče, društvene '
      'teme, sport i informacije koje privlače pažnju javnosti — brzo, jasno '
      'i direktno.';

  /// Koliko vesti se učitava odjednom.
  static const int pageSize = 20;
}
