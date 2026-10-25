import 'package:flutter/material.dart';

import '../api.dart';
import '../config.dart';
import '../home_feed.dart';
import '../models.dart';
import '../post_list.dart';
import '../saved_store.dart';
import '../theme.dart';
import '../widgets.dart';

/// Naslovna: isti raspored kao mobilna verzija sajta prvavest.com.
/// Ako sajt ne može da se pročita, prikazuje se obična lista vesti.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  late Future<List<HomeSection>> _future = HomeFeed.load();

  @override
  bool get wantKeepAlive => true;

  Future<void> _refresh() async {
    final f = HomeFeed.load(refresh: true);
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<HomeSection>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final sections = snap.data ?? const <HomeSection>[];
        if (snap.hasError || sections.isEmpty) {
          // Rezerva: obična lista najnovijih vesti.
          return const PostListView(style: PostListStyle.home);
        }
        return RefreshIndicator(
          color: AppConfig.brandColor,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8),
            children: [
              for (final s in sections) _Section(section: s),
              const SizedBox(height: 24),
              const SiteFooter(),
            ],
          ),
        );
      },
    );
  }
}

/// Najnovije: sve vesti redom, sa brojevima kao na sajtu.
class LatestScreen extends StatelessWidget {
  const LatestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PostListView(style: PostListStyle.numbered);
  }
}

// ---------------------------------------------------------------------------
// Boje (kao na sajtu)
// ---------------------------------------------------------------------------

/// Boja tačke pored naslova rubrike.
Color _dotColor(String title) {
  switch (title.toLowerCase()) {
    case 'svet':
      return const Color(0xFF3B8EEA);
    case 'tehnologija':
      return const Color(0xFF2EB872);
    case 'izbor urednika':
      return AppConfig.inkColor;
    case 'popularno':
    case 'kolumna':
    case 'najnovije vesti':
      return const Color(0xFFE53935);
    default:
      return AppConfig.brandColor;
  }
}

/// Boja okvira oznake rubrike (Sport narandžasto, Hronika tamno...).
Color _pillColor(String category) {
  const dark = {'hronika', 'beograd', 'izbori 2026', 'kolumna', 'recepti'};
  final c = category.toLowerCase();
  if (c == 'svet') return const Color(0xFFE53935);
  if (dark.contains(c)) return AppConfig.inkColor;
  return AppConfig.brandColor;
}

class _Colors {
  final Color ink;
  final Color muted;
  final Color line;
  const _Colors(this.ink, this.muted, this.line);

  static _Colors of(BuildContext context, bool dark) => dark
      ? const _Colors(Colors.white, Colors.white60, Colors.white24)
      : _Colors(context.ink, context.muted, context.line);
}

// ---------------------------------------------------------------------------
// Rubrika
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  final HomeSection section;
  const _Section({required this.section});

  @override
  Widget build(BuildContext context) {
    final dark = section.dark;
    final c = _Colors.of(context, dark);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (section.title.isNotEmpty)
          _SectionHeading(section: section, colors: c),
        for (final b in section.blocks) _Block(block: b, dark: dark),
      ],
    );

    if (dark) {
      return Container(
        margin: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: content,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
      child: content,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final HomeSection section;
  final _Colors colors;
  const _SectionHeading({required this.section, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _dotColor(section.title),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
              ),
              if (section.moreUrl != null)
                InkWell(
                  onTap: () => _openMore(context, section.moreUrl!),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 18, color: colors.ink),
                        const SizedBox(width: 4),
                        Text(
                          'Prikaži više',
                          style: TextStyle(fontSize: 14, color: colors.ink),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1.2, color: colors.ink),
        ],
      ),
    );
  }
}

/// "Prikaži više": otvara rubriku u aplikaciji ako je prepoznamo.
Future<void> _openMore(BuildContext context, String url) async {
  final segments = Uri.tryParse(url)?.pathSegments.where((s) => s.isNotEmpty);
  final slug = (segments == null || segments.isEmpty) ? '' : segments.last;
  try {
    final cats = await WordPressApi.instance.categories();
    for (final c in cats) {
      if (c.slug == slug) {
        if (context.mounted) openCategory(context, c);
        return;
      }
    }
  } catch (_) {}
  if (context.mounted) await openLink(context, url);
}

// ---------------------------------------------------------------------------
// Blokovi
// ---------------------------------------------------------------------------

class _Block extends StatelessWidget {
  final HomeBlock block;
  final bool dark;
  const _Block({required this.block, required this.dark});

  @override
  Widget build(BuildContext context) {
    final c = _Colors.of(context, dark);
    final items = block.items;
    Widget divider() => Container(height: 1, color: c.line);

    switch (block.kind) {
      case BlockKind.hero:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroItem(item: items.first, colors: c),
            for (final it in items.skip(1)) ...[
              divider(),
              _RowItem(item: it, colors: c, dark: dark),
            ],
          ],
        );

      case BlockKind.rows:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) divider(),
              _RowItem(item: items[i], colors: c, dark: dark),
            ],
          ],
        );

      case BlockKind.cards:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) divider(),
              _CardItem(item: items[i], colors: c, dark: dark),
            ],
          ],
        );

      case BlockKind.small:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              divider(),
              _SmallItem(item: items[i], colors: c, dark: dark),
            ],
          ],
        );

      case BlockKind.text:
        if (block.columns == 2) {
          final rows = <Widget>[];
          for (var i = 0; i < items.length; i += 2) {
            if (i > 0) rows.add(divider());
            rows.add(IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _TextItem(item: items[i], colors: c, dark: dark),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: c.line,
                  ),
                  Expanded(
                    child: i + 1 < items.length
                        ? _TextItem(item: items[i + 1], colors: c, dark: dark)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ));
          }
          return Column(children: rows);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) divider(),
              _ColumnItem(item: items[i], colors: c),
            ],
          ],
        );

      case BlockKind.carousel:
        return _Carousel(items: items);
    }
  }
}

// ---------------------------------------------------------------------------
// Vesti
// ---------------------------------------------------------------------------

TextStyle _titleStyle(Color color, double size) => TextStyle(
      fontFamily: kSerif,
      fontSize: size,
      height: 1.25,
      fontWeight: FontWeight.w800,
      color: color,
    );

/// "Autor Ime Prezime //"
class _Author extends StatelessWidget {
  final HomeItem item;
  final _Colors colors;
  final bool slashes;
  final String? date;
  const _Author({
    required this.item,
    required this.colors,
    this.slashes = true,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = (date ?? '').isNotEmpty;
    if (item.author.isEmpty && !hasDate) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(children: [
        if (item.author.isNotEmpty) ...[
          TextSpan(
            text: 'Autor ',
            style: TextStyle(fontSize: 13, color: colors.muted),
          ),
          TextSpan(
            text: item.author,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
          ),
        ],
        if (item.author.isNotEmpty && (slashes || hasDate))
          TextSpan(
            text: '  //  ',
            style: TextStyle(fontSize: 10, color: colors.muted),
          ),
        if (hasDate)
          TextSpan(
            text: _capitalize(date!),
            style: TextStyle(fontSize: 13, color: colors.muted),
          ),
      ]),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _Pill extends StatelessWidget {
  final String text;
  final bool dark;
  const _Pill(this.text, {required this.dark});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    var color = dark ? Colors.white : _pillColor(text);
    // Tamne oznake u noćnoj verziji postaju svetle.
    if (color == AppConfig.inkColor) color = context.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Ikonica za čuvanje vesti sa naslovne (vest se preuzme po potrebi).
class _Bookmark extends StatefulWidget {
  final HomeItem item;
  final Color color;
  const _Bookmark({required this.item, required this.color});

  @override
  State<_Bookmark> createState() => _BookmarkState();
}

class _BookmarkState extends State<_Bookmark> {
  bool _busy = false;

  Future<void> _toggle(bool saved) async {
    final store = SavedStore.instance;
    final messenger = ScaffoldMessenger.of(context);
    void say(String t) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(t),
        duration: const Duration(seconds: 2),
      ));

    if (saved) {
      await store.removeLink(widget.item.url);
      say('Vest je uklonjena iz sačuvanih.');
      return;
    }
    setState(() => _busy = true);
    try {
      final Post? post = await WordPressApi.instance.postByUrl(widget.item.url);
      if (post == null) throw Exception('nema vesti');
      if (!store.isSaved(post.id)) await store.toggle(post);
      say('Vest je sačuvana.');
    } catch (_) {
      say('Vest trenutno ne može da se sačuva.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = SavedStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final saved = store.isSavedLink(widget.item.url);
        return IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: saved ? 'Ukloni iz sačuvanih' : 'Sačuvaj vest',
          onPressed: _busy ? null : () => _toggle(saved),
          icon: _busy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.color,
                  ),
                )
              : Icon(
                  saved ? Icons.bookmark : Icons.bookmark_border,
                  color: saved ? AppConfig.brandColor : widget.color,
                ),
        );
      },
    );
  }
}

/// Glavna vest na vrhu.
class _HeroItem extends StatelessWidget {
  final HomeItem item;
  final _Colors colors;
  const _HeroItem({required this.item, required this.colors});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openArticleUrl(context, item.url),
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(url: item.image, radius: BorderRadius.circular(4)),
                  if (item.categories.isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 30, 14, 12),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(4),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha(0),
                              Colors.black.withAlpha(150),
                            ],
                          ),
                        ),
                        child: Text(
                          item.categories
                              .map((e) => e.toUpperCase())
                              .join('  /  '),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(item.title, style: _titleStyle(colors.ink, 25)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _Author(item: item, colors: colors, date: item.date),
                ),
                _Bookmark(item: item, color: colors.ink),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Slika levo, gore autor i rubrika, ispod naslov.
class _RowItem extends StatelessWidget {
  final HomeItem item;
  final _Colors colors;
  final bool dark;
  const _RowItem({
    required this.item,
    required this.colors,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openArticleUrl(context, item.url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetImage(
              url: item.image,
              width: 130,
              height: 100,
              radius: BorderRadius.circular(4),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _Author(item: item, colors: colors),
                            _Pill(item.category, dark: dark),
                          ],
                        ),
                      ),
                      _Bookmark(item: item, color: colors.ink),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: _titleStyle(colors.ink, 16.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Velika slika, ispod autor, rubrika i naslov.
class _CardItem extends StatelessWidget {
  final HomeItem item;
  final _Colors colors;
  final bool dark;
  const _CardItem({
    required this.item,
    required this.colors,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openArticleUrl(context, item.url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: NetImage(
                url: item.largeImage,
                radius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Author(item: item, colors: colors),
                      _Pill(item.category, dark: dark),
                    ],
                  ),
                ),
                _Bookmark(item: item, color: colors.ink),
              ],
            ),
            const SizedBox(height: 4),
            Text(item.title, style: _titleStyle(colors.ink, 19)),
          ],
        ),
      ),
    );
  }
}

/// Samo naslov (Popularno, u dve kolone).
class _TextItem extends StatelessWidget {
  final HomeItem item;
  final _Colors colors;
  final bool dark;
  const _TextItem({
    required this.item,
    required this.colors,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openArticleUrl(context, item.url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.redo, size: 17, color: colors.ink),
                  ),
                ),
                TextSpan(text: item.title),
              ]),
              style: _titleStyle(colors.ink, 15.5),
            ),
            const SizedBox(height: 10),
            _Author(item: item, colors: colors),
            Row(
              children: [
                Flexible(child: _Pill(item.category, dark: dark)),
                const Spacer(),
                _Bookmark(item: item, color: colors.ink),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Kolumna: krupan naslov i autor.
class _ColumnItem extends StatelessWidget {
  final HomeItem item;
  final _Colors colors;
  const _ColumnItem({required this.item, required this.colors});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openArticleUrl(context, item.url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: _titleStyle(colors.ink, 21)),
            const SizedBox(height: 10),
            Row(
              children: [
                if (item.image != null) ...[
                  ClipOval(
                    child: NetImage(url: item.image, width: 46, height: 46),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: _Author(item: item, colors: colors, slashes: false),
                ),
                _Bookmark(item: item, color: colors.ink),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Mala slika levo, rubrika iznad naslova (blok Sport).
class _SmallItem extends StatelessWidget {
  final HomeItem item;
  final _Colors colors;
  final bool dark;
  const _SmallItem({
    required this.item,
    required this.colors,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openArticleUrl(context, item.url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetImage(
              url: item.image,
              width: 110,
              height: 80,
              radius: BorderRadius.circular(4),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.category.isNotEmpty)
                    Text(
                      item.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: dark ? Colors.white : AppConfig.brandTextColor,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: _titleStyle(colors.ink, 15.5),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _Author(
                          item: item,
                          colors: colors,
                          slashes: false,
                        ),
                      ),
                      _Bookmark(item: item, color: colors.ink),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Izbor urednika: vrteška sa velikim slikama.
class _Carousel extends StatefulWidget {
  final List<HomeItem> items;
  const _Carousel({required this.items});

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  final _controller = PageController(viewportFraction: 0.9);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const white = _Colors(Colors.white, Colors.white70, Colors.white24);
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: _controller,
              padEnds: false,
              itemCount: widget.items.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => _CarouselCard(
                item: widget.items[i],
                colors: white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.items.length; i++)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page ? context.ink : context.line,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  final HomeItem item;
  final _Colors colors;
  const _CarouselCard({required this.item, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () => openArticleUrl(context, item.url),
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetImage(url: item.largeImage, radius: BorderRadius.circular(6)),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.35, 1],
                  colors: [
                    Colors.black.withAlpha(0),
                    Colors.black.withAlpha(215),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 6,
              bottom: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: _titleStyle(Colors.white, 19),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _Author(item: item, colors: colors),
                            _Pill(item.category, dark: true),
                          ],
                        ),
                      ),
                      _Bookmark(item: item, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
