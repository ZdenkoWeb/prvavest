// Čita naslovnu stranu sajta prvavest.com i pretvara je u blokove
// koje aplikacija crta isto kao mobilni sajt. Kad urednik na sajtu
// promeni raspored (rubrike, Popularno, Izbor urednika), aplikacija
// to prikaže sama, bez nove verzije.
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;

import 'api.dart';

/// Kako se blok vesti crta.
enum BlockKind {
  /// Glavna vest: velika slika i krupan naslov.
  hero,

  /// Slika levo, naslov desno.
  rows,

  /// Velika slika, ispod naslov.
  cards,

  /// Samo naslovi (Popularno, Kolumna).
  text,

  /// Mala slika levo, rubrika iznad naslova (npr. u bloku Sport).
  small,

  /// Vrteška sa slikama preko celog bloka (Izbor urednika).
  carousel,
}

class HomeItem {
  final String title;
  final String url;
  final String? image;
  final List<String> categories;
  final String author;
  final String date;

  const HomeItem({
    required this.title,
    required this.url,
    this.image,
    this.categories = const [],
    this.author = '',
    this.date = '',
  });

  String get category => categories.isEmpty ? '' : categories.first;

  /// Ista slika u punoj veličini (bez "-330x220" u imenu), za velike
  /// slike, da ne budu mutne.
  String? get largeImage => image?.replaceFirst(
        RegExp(r'-\d+x\d+(?=\.(jpe?g|png|webp|gif)$)', caseSensitive: false),
        '',
      );
}

class HomeBlock {
  final BlockKind kind;
  final List<HomeItem> items;

  /// Koliko kolona na telefonu (Popularno ima 2).
  final int columns;

  const HomeBlock(this.kind, this.items, {this.columns = 1});
}

/// Rubrika na naslovnoj: naslov (može biti prazan za vrh strane)
/// i jedan ili više blokova vesti ispod njega.
class HomeSection {
  final String title;
  final String? moreUrl;
  final bool dark;
  final List<HomeBlock> blocks;

  HomeSection({
    required this.title,
    this.moreUrl,
    this.dark = false,
    List<HomeBlock>? blocks,
  }) : blocks = blocks ?? [];
}

class HomeFeed {
  HomeFeed._();

  static List<HomeSection>? _cache;
  static DateTime _cacheAt = DateTime(2000);

  /// Naslovna sa sajta. Pamti se 3 minuta; refresh: true učitava ponovo.
  static Future<List<HomeSection>> load({bool refresh = false}) async {
    final fresh = DateTime.now().difference(_cacheAt).inMinutes < 3;
    if (!refresh && fresh && _cache != null) return _cache!;
    final page = await WordPressApi.instance.fetchHomeHtml();
    final sections = parse(page);
    if (sections.isNotEmpty) {
      _cache = sections;
      _cacheAt = DateTime.now();
    }
    return sections;
  }

  static List<HomeSection> parse(String page) {
    final doc = html.parse(page);
    final widgets = doc
        .querySelectorAll('.elementor-widget')
        .where(_isTopLevel)
        .where((w) => (w.attributes['data-widget_type'] ?? '').startsWith('foxiz-'))
        .toList();

    final sections = <HomeSection>[];
    HomeSection? current;

    for (final w in widgets) {
      final type = (w.attributes['data-widget_type'] ?? '')
          .replaceAll('.default', '')
          .replaceFirst('foxiz-', '');

      if (type == 'heading') {
        final title = _text(w.querySelector('.heading-title'));
        if (title.isEmpty) continue;
        String? more;
        for (final a in w.querySelectorAll('a')) {
          final href = a.attributes['href'] ?? '';
          if (href.contains('/kategorija/') || href.contains('/category/') ||
              _text(a).toLowerCase().contains('prikaži')) {
            more = href;
            break;
          }
        }
        current = HomeSection(title: title, moreUrl: more);
        sections.add(current);
        continue;
      }

      final block = _parseBlock(type, w);
      if (block == null) continue;

      if (current == null) {
        current = HomeSection(title: '', dark: _isDark(w));
        sections.add(current);
      } else if (current.blocks.isEmpty && _isDark(w) && !current.dark) {
        // Rubrika je tamna ako je njen prvi blok tamni (Svet, Sport).
        final dark = HomeSection(
          title: current.title,
          moreUrl: current.moreUrl,
          dark: true,
        );
        sections[sections.length - 1] = dark;
        current = dark;
      }
      current.blocks.add(block);
    }

    // Naslovi bez vesti (npr. Shorts, video) se ne prikazuju.
    sections.removeWhere((s) => s.blocks.isEmpty);
    return sections;
  }

  static HomeBlock? _parseBlock(String type, dom.Element w) {
    final items = w
        .querySelectorAll('.p-wrap')
        .map(_parseItem)
        .whereType<HomeItem>()
        .toList();
    if (items.isEmpty) return null;

    final wrapClasses = w.querySelector('.block-wrap')?.classes ?? <String>{};

    if (type.startsWith('overlay')) return HomeBlock(BlockKind.carousel, items);
    if (type == 'list-1' || type == 'list-2') {
      return HomeBlock(BlockKind.hero, items);
    }
    if (type.startsWith('list-small-1')) {
      final cols = wrapClasses.contains('rb-mcol-2') ? 2 : 1;
      return HomeBlock(BlockKind.text, items, columns: cols);
    }
    if (type.startsWith('list-small')) return HomeBlock(BlockKind.small, items);
    if (type.startsWith('grid') || type.startsWith('list')) {
      final mobileList = wrapClasses.contains('is-m-list');
      return HomeBlock(mobileList ? BlockKind.rows : BlockKind.cards, items);
    }
    return null;
  }

  static HomeItem? _parseItem(dom.Element p) {
    final link = p.querySelector('.entry-title a');
    if (link == null) return null;
    final url = link.attributes['href'] ?? '';
    final title = _text(link);
    if (url.isEmpty || title.isEmpty) return null;

    String? image;
    final img = p.querySelector('.p-featured img') ?? p.querySelector('img');
    if (img != null) {
      image = _bestSrc(img);
    }

    var cats = p
        .querySelectorAll('.p-categories a')
        .map(_text)
        .where((t) => t.isNotEmpty)
        .toList();
    if (cats.isEmpty) {
      cats = p
          .querySelectorAll('.meta-tax a')
          .map(_text)
          .where((t) => t.isNotEmpty)
          .toList();
    }

    var author = _text(p.querySelector('.meta-author a')) ;
    if (author.isEmpty) {
      author = _text(p.querySelector('.meta-author'))
          .replaceFirst(RegExp(r'^Autor\s*'), '')
          .trim();
    }

    final date = _text(
      p.querySelector('.meta-update') ?? p.querySelector('.meta-date'),
    );

    return HomeItem(
      title: title,
      url: url,
      image: image,
      categories: cats.toSet().toList(),
      author: author,
      date: date,
    );
  }

  /// Najbolja adresa slike: iz srcset biramo verziju širine do ~900px.
  static String? _bestSrc(dom.Element img) {
    String? src;
    for (final key in ['data-src', 'src', 'data-lazy-src']) {
      final v = img.attributes[key];
      if (v != null && v.startsWith('http')) {
        src = v;
        break;
      }
    }
    final srcset = img.attributes['srcset'] ?? img.attributes['data-srcset'];
    if (srcset != null && srcset.isNotEmpty) {
      var bestW = 0;
      for (final part in srcset.split(',')) {
        final bits = part.trim().split(RegExp(r'\s+'));
        if (bits.length < 2) continue;
        final w = int.tryParse(bits[1].replaceAll('w', '')) ?? 0;
        if (w <= 1000 && w > bestW) {
          bestW = w;
          src = bits[0];
        }
      }
    }
    return src;
  }

  static bool _isTopLevel(dom.Element w) {
    var p = w.parent;
    while (p != null) {
      if (p.classes.contains('elementor-widget')) return false;
      p = p.parent;
    }
    return true;
  }

  static bool _isDark(dom.Element w) {
    final c = w.querySelector('.block-wrap')?.classes ?? <String>{};
    return c.contains('light-scheme');
  }

  static String _text(dom.Element? e) =>
      (e?.text ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
}
