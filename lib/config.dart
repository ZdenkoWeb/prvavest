import 'package:flutter/material.dart';

/// Osnovna podešavanja aplikacije. Ako nešto menjaš na sajtu
/// (logo, boje, kategorije), dovoljno je da promeniš ovde.
class AppConfig {
  static const String appName = 'Prva Vest';
  static const String siteUrl = 'https://prvavest.com';
  static const String apiBase = '$siteUrl/wp-json/wp/v2';

  /// Logo se učitava direktno sa sajta.
  static const String logoUrl =
      '$siteUrl/wp-content/uploads/2022/07/prva-vest-logo-.png';

  /// Glavna boja aplikacije (dugmad, oznake kategorija...).
  static const Color brandColor = Color(0xFFC8102E);

  /// Kategorije koje se prikazuju kao kartice na početnom ekranu,
  /// tim redosledom. Ovo su "slug"-ovi kategorija sa sajta
  /// (deo adrese posle /kategorija/).
  static const List<String> categorySlugs = [
    'izbori-2026',
    'politika',
    'drustvo',
    'hronika',
    'ekonomija',
    'svet',
    'sport',
    'beograd',
    'srbija',
    'tehnologija',
    'kolumna',
    'recepti',
  ];

  /// Koliko vesti se učitava odjednom.
  static const int pageSize = 20;
}
