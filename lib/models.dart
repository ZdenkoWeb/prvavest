/// Podaci o jednoj vesti i jednoj kategoriji, onako kako ih
/// aplikacija koristi. Sve se pravi iz odgovora WordPress API-ja.

class Category {
  final int id;
  final String name;
  final String slug;

  const Category({required this.id, required this.name, required this.slug});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: decodeHtml(json['name']?.toString() ?? ''),
        slug: json['slug']?.toString() ?? '',
      );
}

class Post {
  final int id;
  final String title;
  final String excerpt;
  final String content; // HTML tekst članka
  final String link; // adresa vesti na sajtu
  final DateTime date;
  final DateTime? modified;
  final String author;
  final String category;
  final int? categoryId;
  final List<String> tags;
  final String? imageUrl;

  const Post({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.link,
    required this.date,
    required this.author,
    required this.category,
    this.categoryId,
    this.modified,
    this.tags = const [],
    this.imageUrl,
  });

  /// Pravi vest iz odgovora WordPress API-ja (sa ?_embed).
  factory Post.fromWordPress(Map<String, dynamic> json) {
    final embedded = json['_embedded'] as Map<String, dynamic>? ?? {};

    // Autor
    var author = '';
    final authors = embedded['author'];
    if (authors is List && authors.isNotEmpty && authors.first is Map) {
      author = decodeHtml((authors.first as Map)['name']?.toString() ?? '');
    }

    // Glavna slika (biramo srednju veličinu da se brže učitava)
    String? image;
    final media = embedded['wp:featuredmedia'];
    if (media is List && media.isNotEmpty && media.first is Map) {
      final m = media.first as Map;
      final sizes = (m['media_details'] is Map)
          ? (m['media_details'] as Map)['sizes'] as Map?
          : null;
      for (final size in ['medium_large', 'large', 'full']) {
        final s = sizes?[size];
        if (s is Map && s['source_url'] != null) {
          image = s['source_url'].toString();
          break;
        }
      }
      image ??= m['source_url']?.toString();
    }

    // Kategorija (prva) i oznake (tagovi)
    var category = '';
    int? categoryId;
    final tags = <String>[];
    final terms = embedded['wp:term'];
    if (terms is List) {
      for (final group in terms) {
        if (group is! List) continue;
        for (final t in group) {
          if (t is! Map) continue;
          final name = decodeHtml(t['name']?.toString() ?? '');
          if (name.isEmpty) continue;
          if (t['taxonomy'] == 'category' && category.isEmpty) {
            category = name;
            categoryId = t['id'] is int ? t['id'] as int : null;
          } else if (t['taxonomy'] == 'post_tag') {
            tags.add(name);
          }
        }
      }
    }

    return Post(
      id: json['id'] as int,
      title: decodeHtml(_rendered(json['title'])),
      excerpt: decodeHtml(stripTags(_rendered(json['excerpt']))),
      content: _rendered(json['content']),
      link: json['link']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      modified: DateTime.tryParse(json['modified']?.toString() ?? ''),
      author: author,
      category: category,
      categoryId: categoryId,
      tags: tags,
      imageUrl: image,
    );
  }

  /// Za čuvanje vesti u telefonu (Sačuvano).
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'excerpt': excerpt,
        'content': content,
        'link': link,
        'date': date.toIso8601String(),
        'modified': modified?.toIso8601String(),
        'author': author,
        'category': category,
        'categoryId': categoryId,
        'tags': tags,
        'imageUrl': imageUrl,
      };

  factory Post.fromMap(Map<String, dynamic> m) => Post(
        id: m['id'] as int,
        title: m['title']?.toString() ?? '',
        excerpt: m['excerpt']?.toString() ?? '',
        content: m['content']?.toString() ?? '',
        link: m['link']?.toString() ?? '',
        date: DateTime.tryParse(m['date']?.toString() ?? '') ?? DateTime.now(),
        modified: DateTime.tryParse(m['modified']?.toString() ?? ''),
        author: m['author']?.toString() ?? '',
        category: m['category']?.toString() ?? '',
        categoryId: m['categoryId'] is int ? m['categoryId'] as int : null,
        tags: (m['tags'] is List)
            ? (m['tags'] as List).map((e) => e.toString()).toList()
            : const [],
        imageUrl: m['imageUrl']?.toString(),
      );

  /// Datum na srpskom, npr. "21. oktobar 2026."
  String get dateLabel => formatDate(date);
}

String _rendered(dynamic field) {
  if (field is Map && field['rendered'] != null) {
    return field['rendered'].toString();
  }
  return field?.toString() ?? '';
}

/// Uklanja HTML oznake iz teksta.
String stripTags(String html) => html
    .replaceAll(RegExp(r'<[^>]*>'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Pretvara HTML oznake za znakove (npr. &#8220; ili &amp;) u prave znakove.
String decodeHtml(String text) {
  var out = text.replaceAllMapped(RegExp(r'&#(x?)([0-9a-fA-F]+);'), (m) {
    final code = int.tryParse(m[2]!, radix: m[1]!.isEmpty ? 10 : 16);
    return code == null ? m[0]! : String.fromCharCode(code);
  });
  const named = {
    '&amp;': '&',
    '&quot;': '"',
    '&apos;': "'",
    '&lt;': '<',
    '&gt;': '>',
    '&nbsp;': ' ',
    '&hellip;': '…',
    '&ndash;': '–',
    '&mdash;': '—',
    '&laquo;': '«',
    '&raquo;': '»',
    '&bdquo;': '„',
    '&ldquo;': '“',
    '&rdquo;': '”',
    '&lsquo;': '‘',
    '&rsquo;': '’',
  };
  named.forEach((k, v) => out = out.replaceAll(k, v));
  return out.trim();
}

const _months = [
  'januar', 'februar', 'mart', 'april', 'maj', 'jun',
  'jul', 'avgust', 'septembar', 'oktobar', 'novembar', 'decembar',
];

/// "pre 5 min", "pre 3 h", a starije vesti sa datumom.
String formatDate(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 60 && !diff.isNegative) {
    final m = diff.inMinutes < 1 ? 1 : diff.inMinutes;
    return 'pre $m min';
  }
  if (diff.inHours < 24 && !diff.isNegative) {
    return 'pre ${diff.inHours} h';
  }
  return '${d.day}. ${_months[d.month - 1]} ${d.year}.';
}

/// Uvek relativno, kao u traci NAJNOVIJE: "pre 2 dana".
String relativeLabel(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.isNegative || diff.inMinutes < 1) return 'upravo';
  if (diff.inMinutes < 60) return 'pre ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'pre ${diff.inHours} h';
  final days = diff.inDays;
  final word = (days % 10 == 1 && days % 100 != 11) ? 'dan' : 'dana';
  return 'pre $days $word';
}

/// "21. oktobar 2026, 14:27"
String formatDateTime(DateTime d) {
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day}. ${_months[d.month - 1]} ${d.year}, $hh:$mm';
}
