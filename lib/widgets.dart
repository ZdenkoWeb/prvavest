import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'logo_data.dart';
import 'models.dart';
import 'saved_store.dart';
import 'screens/article_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/search_screen.dart';
import 'theme.dart';

// ---------------------------------------------------------------------------
// Navigacija
// ---------------------------------------------------------------------------

void openArticle(BuildContext context, Post post) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ArticleScreen(post: post)),
  );
}

/// Otvara vest po adresi sa sajta (vest se prvo preuzme).
void openArticleUrl(BuildContext context, String url) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ArticleLoader(url: url)),
  );
}

void openCategory(BuildContext context, Category category) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => CategoryScreen(category: category)),
  );
}

void openSearch(BuildContext context, {String? query}) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => SearchScreen(initialQuery: query)),
  );
}

/// Otvara link u pregledaču ili drugoj aplikaciji (WhatsApp, Viber...).
Future<void> openLink(BuildContext context, String url) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Link ne može da se otvori.')),
      );
  }
}

/// Ime kategorije onako kako se prikazuje u traci (#Izbori2026, SRBIJA...).
String chipLabel(Category c) => c.slug == AppConfig.highlightedSlug
    ? '#${c.name.replaceAll(' ', '')}'
    : c.name.toUpperCase();

// ---------------------------------------------------------------------------
// Logo
// ---------------------------------------------------------------------------

bool _isLight(Color c) => c.computeLuminance() > 0.5;

/// Znak "1V" iz pravog logoa. Bela verzija se bira sama
/// kad je tekst svetao (tamna tema ili crna pozadina).
class OneVMark extends StatelessWidget {
  final double size;
  final Color? oneColor;
  const OneVMark({super.key, this.size = 26, this.oneColor});

  @override
  Widget build(BuildContext context) {
    final white = _isLight(oneColor ?? context.ink);
    return Image.memory(
      white ? LogoData.markWhite : LogoData.mark,
      height: size * 1.1,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      semanticLabel: AppConfig.appName,
    );
  }
}

/// Pravi logo PRVA 1V EST. U tamnoj temi koristi belu verziju.
class PrvaVestLogo extends StatelessWidget {
  final double height;
  const PrvaVestLogo({super.key, this.height = 30});

  @override
  Widget build(BuildContext context) {
    final white = _isLight(context.ink);
    return Image.memory(
      white ? LogoData.logoWhite : LogoData.logo,
      height: height * 1.3,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      semanticLabel: AppConfig.appName,
    );
  }
}

// ---------------------------------------------------------------------------
// Sitni delovi
// ---------------------------------------------------------------------------

/// Slika sa interneta koja se pamti u telefonu (brže drugi put).
class NetImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BorderRadius radius;

  const NetImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: context.box,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: context.muted),
    );
    if (url == null || url!.isEmpty) {
      return ClipRRect(borderRadius: radius, child: placeholder);
    }
    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
}

/// Narandžasti natpis kategorije (SPORT) iznad naslova.
class CategoryLabel extends StatelessWidget {
  final String text;
  final double size;
  const CategoryLabel(this.text, {super.key, this.size = 12});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: AppConfig.brandTextColor,
      ),
    );
  }
}

/// Kategorija u narandžastom okviru (kao "Ekonomija" na sajtu).
class CategoryPill extends StatelessWidget {
  final String text;
  const CategoryPill(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: AppConfig.brandColor, width: 1.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppConfig.brandTextColor,
        ),
      ),
    );
  }
}

void _showSavedSnack(BuildContext context, bool nowSaved) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(nowSaved
          ? 'Vest je sačuvana.'
          : 'Vest je uklonjena iz sačuvanih.'),
      duration: const Duration(seconds: 2),
    ));
}

/// Ikonica za čuvanje vesti (desno, kao na sajtu).
class BookmarkButton extends StatelessWidget {
  final Post post;
  const BookmarkButton({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final store = SavedStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final saved = store.isSaved(post.id);
        return IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: saved ? 'Ukloni iz sačuvanih' : 'Sačuvaj vest',
          icon: Icon(
            saved ? Icons.bookmark : Icons.bookmark_border,
            color: saved ? AppConfig.brandColor : context.ink,
          ),
          onPressed: () {
            store.toggle(post);
            _showSavedSnack(context, !saved);
          },
        );
      },
    );
  }
}

/// Dugme "Sačuvaj" u okviru (na stranici vesti).
class SaveChip extends StatelessWidget {
  final Post post;
  const SaveChip({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final store = SavedStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final saved = store.isSaved(post.id);
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            store.toggle(post);
            _showSavedSnack(context, !saved);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: context.line, width: 1.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                saved ? Icons.bookmark : Icons.bookmark_border,
                size: 18,
                color: saved ? AppConfig.brandColor : context.ink,
              ),
              const SizedBox(width: 6),
              Text(
                saved ? 'Sačuvano' : 'Sačuvaj',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.ink,
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

/// "Autor Ime Prezime // 21. oktobar 2026."
class AuthorLine extends StatelessWidget {
  final Post post;
  final bool showDate;
  const AuthorLine({super.key, required this.post, this.showDate = true});

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(fontSize: 13.5, color: context.muted);
    final strong = TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      color: context.ink,
    );
    final parts = <InlineSpan>[];
    if (post.author.isNotEmpty) {
      parts.add(TextSpan(text: 'Autor ', style: muted));
      parts.add(TextSpan(text: post.author, style: strong));
    }
    if (showDate) {
      if (parts.isNotEmpty) {
        parts.add(TextSpan(text: '  //  ', style: muted.copyWith(fontSize: 11)));
      }
      parts.add(TextSpan(text: post.dateLabel, style: muted));
    }
    return Text.rich(
      TextSpan(children: parts),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Naslov kao naslovna rubrika: veliki tekst sa narandžastom crtom ispod.
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontFamily: kSerif,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.ink,
            ),
          ),
          const SizedBox(height: 8),
          Container(width: 44, height: 3, color: AppConfig.brandColor),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kartice sa vestima
// ---------------------------------------------------------------------------

/// Glavna vest: velika slika sa rubrikom u uglu i krupan naslov.
class HeroPost extends StatelessWidget {
  final Post post;
  const HeroPost({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openArticle(context, post),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetImage(url: post.imageUrl, radius: BorderRadius.circular(6)),
                if (post.category.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 28, 14, 12),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(6),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(0),
                            Colors.black.withAlpha(140),
                          ],
                        ),
                      ),
                      child: Text(
                        post.category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            post.title,
            style: TextStyle(
              fontFamily: kSerif,
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: context.ink,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: AuthorLine(post: post)),
              BookmarkButton(post: post),
            ],
          ),
        ],
      ),
    );
  }
}

/// Vest u listi: slika levo, naslov desno. Sa brojem (1, 2, 3...)
/// izgleda kao lista "najnovije" na sajtu.
class RowPost extends StatelessWidget {
  final Post post;
  final int? number;
  const RowPost({super.key, required this.post, this.number});

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontFamily: kSerif,
      fontSize: 17,
      height: 1.28,
      fontWeight: FontWeight.w800,
      color: context.ink,
    );

    return InkWell(
      onTap: () => openArticle(context, post),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetImage(
              url: post.imageUrl,
              width: 108,
              height: 108,
              radius: BorderRadius.circular(4),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (number == null && post.category.isNotEmpty) ...[
                    CategoryPill(post.category),
                    const SizedBox(height: 8),
                  ],
                  Text.rich(
                    TextSpan(children: [
                      if (number != null)
                        TextSpan(
                          text: '$number  ',
                          style: titleStyle.copyWith(
                            fontSize: 34,
                            height: 1.05,
                            color: AppConfig.brandColor,
                          ),
                        ),
                      TextSpan(text: post.title),
                    ]),
                    style: titleStyle,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Expanded(child: AuthorLine(post: post)),
                      BookmarkButton(post: post),
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

// ---------------------------------------------------------------------------
// Ostalo
// ---------------------------------------------------------------------------

/// Crni deo na dnu (kao podnožje sajta).
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    const grey = Color(0xFFB4B4B8);
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OneVMark(size: 40, oneColor: Colors.white),
          const SizedBox(height: 22),
          const Text(
            AppConfig.aboutText,
            style: TextStyle(
              fontFamily: kSerif,
              fontSize: 16,
              height: 1.7,
              color: grey,
            ),
          ),
          const SizedBox(height: 22),
          InkWell(
            onTap: () => openLink(context, AppConfig.siteUrl),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  'prvavest.com',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.open_in_new, color: Colors.white, size: 16),
              ]),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            '© Prva Vest. Sva prava zadržana.',
            style: TextStyle(fontFamily: kSerif, fontSize: 14, color: grey),
          ),
        ],
      ),
    );
  }
}

/// Poruka o grešci sa dugmetom "Pokušaj ponovo".
class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorRetry({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 40, color: context.muted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.ink),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      ),
    );
  }
}
