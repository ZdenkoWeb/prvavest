import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'models.dart';

/// Sve što aplikacija traži od sajta prolazi kroz ovu klasu.
/// Koristi ugrađeni WordPress REST API (prvavest.com/wp-json/wp/v2).
class WordPressApi {
  WordPressApi._();
  static final WordPressApi instance = WordPressApi._();

  final http.Client _client = http.Client();

  static const _headers = {
    'Accept': 'application/json',
    'User-Agent': 'PrvaVestApp/1.1 (Android)',
  };

  Future<dynamic> _get(String path, Map<String, String> query) async {
    final uri =
        Uri.parse('${AppConfig.apiBase}/$path').replace(queryParameters: query);
    final res = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));

    // WordPress vraća 400 kad tražimo stranu posle poslednje.
    if (res.statusCode == 400 &&
        res.body.contains('rest_post_invalid_page_number')) {
      return <dynamic>[];
    }
    if (res.statusCode != 200) {
      throw ApiException('Sajt je vratio grešku ${res.statusCode}.');
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  Future<List<Category>>? _categories;

  /// Kategorije se učitavaju jednom i pamte (koriste ih traka,
  /// meni i ekran Kategorije). refresh: true ih učitava ponovo.
  Future<List<Category>> categories({bool refresh = false}) {
    if (refresh) _categories = null;
    return _categories ??= fetchCategories().catchError((Object e) {
      _categories = null; // bez interneta: sledeći put pokušaj ponovo
      throw e;
    });
  }

  Future<List<Post>>? _latest;
  DateTime _latestAt = DateTime(2000);

  /// Najnovije vesti za traku NAJNOVIJE. Pamte se 5 minuta, da se
  /// traka ne učitava iznova na svakom ekranu.
  Future<List<Post>> latest({bool refresh = false}) {
    final stale = DateTime.now().difference(_latestAt).inMinutes >= 5;
    if (_latest == null || stale || refresh) {
      _latestAt = DateTime.now();
      _latest = fetchPosts().catchError((Object e) {
        _latest = null; // sledeći put pokušaj ponovo
        throw e;
      });
    }
    return _latest!;
  }

  /// HTML naslovne strane sajta (iz njega aplikacija čita raspored
  /// blokova: glavna vest, Popularno, rubrike...).
  Future<String> fetchHomeHtml() async {
    final res = await _client.get(
      Uri.parse('${AppConfig.siteUrl}/'),
      headers: const {
        'Accept': 'text/html',
        // Tražimo mobilnu verziju sajta.
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/130.0 Mobile Safari/537.36 PrvaVestApp',
      },
    ).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw ApiException('Sajt je vratio grešku ${res.statusCode}.');
    }
    return utf8.decode(res.bodyBytes, allowMalformed: true);
  }

  final Map<String, Future<Post?>> _byUrl = {};

  /// Vest po adresi sa sajta (npr. https://prvavest.com/naslov-vesti/).
  Future<Post?> postByUrl(String url) {
    return _byUrl[url] ??= _postByUrl(url).catchError((Object e) {
      _byUrl.remove(url);
      throw e;
    });
  }

  Future<Post?> _postByUrl(String url) async {
    final segments = Uri.parse(url).pathSegments.where((s) => s.isNotEmpty);
    if (segments.isEmpty) return null;
    final data = await _get('posts', {
      'slug': Uri.decodeComponent(segments.last),
      '_embed': 'author,wp:featuredmedia,wp:term',
    }) as List;
    if (data.isEmpty) return null;
    return Post.fromWordPress(data.first as Map<String, dynamic>);
  }

  /// Kategorije sa sajta, poređane kao u AppConfig.categorySlugs.
  Future<List<Category>> fetchCategories() async {
    final data = await _get('categories', {
      'per_page': '100',
      '_fields': 'id,name,slug,count',
    }) as List;

    final bySlug = <String, Category>{};
    for (final c in data) {
      final map = c as Map<String, dynamic>;
      if ((map['count'] as int? ?? 0) > 0) {
        final cat = Category.fromJson(map);
        bySlug[cat.slug] = cat;
      }
    }
    return [
      for (final slug in AppConfig.categorySlugs)
        if (bySlug.containsKey(slug)) bySlug[slug]!,
    ];
  }

  /// Vesti. Bez parametara vraća najnovije; može se filtrirati
  /// po kategoriji ili pretraživati po reči.
  Future<List<Post>> fetchPosts({
    int page = 1,
    int? categoryId,
    String? search,
    int? perPage,
  }) async {
    final query = <String, String>{
      'per_page': '${perPage ?? AppConfig.pageSize}',
      'page': '$page',
      '_embed': 'author,wp:featuredmedia,wp:term',
    };
    if (categoryId != null) query['categories'] = '$categoryId';
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final data = await _get('posts', query) as List;
    return data
        .map((p) => Post.fromWordPress(p as Map<String, dynamic>))
        .toList();
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
