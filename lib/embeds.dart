import 'package:flutter/material.dart';

import 'config.dart';
import 'live_embed.dart';
import 'theme.dart';
import 'widgets.dart';
import 'screens/image_viewer.dart';

/// Slike, objave sa X-a (Twittera), Instagrama, TikToka i YouTube
/// snimci u tekstu vesti. Objave se prikazuju prave, kao na sajtu
/// (LiveEmbed); ako se ne učitaju, prikazuje se kartica sa linkom.
///
/// `element` je HTML element iz teksta vesti. Vraća null za sve
/// ostalo, pa se taj deo prikazuje normalno.
Widget? buildEmbed(BuildContext context, dynamic element) {
  final String tag = element.localName ?? '';
  final Set<String> classes = Set<String>.from(element.classes as Iterable);
  final Map attrs = element.attributes as Map;
  final dark = Theme.of(context).brightness == Brightness.dark;

  // Slike u tekstu: uvek preko cele širine ekrana.
  if (tag == 'figure') {
    final img = element.querySelector('img');
    if (img != null && !_isTinyImage(img)) {
      final caption = (element.querySelector('figcaption')?.text ?? '')
          .toString()
          .trim();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ContentImage(
              url: _imgSrc(img),
              aspect: _imgAspect(img),
            ),
            if (caption.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                caption,
                style: TextStyle(fontSize: 13.5, height: 1.4, color: context.muted),
              ),
            ],
          ],
        ),
      );
    }
  }
  if (tag == 'img' && !_isTinyImage(element)) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ContentImage(url: _imgSrc(element), aspect: _imgAspect(element)),
    );
  }

  // X / Twitter
  if (tag == 'blockquote' && classes.contains('twitter-tweet')) {
    var paragraphs = <String>[
      for (final p in element.querySelectorAll('p') as Iterable)
        _cleanTweet(p.text as String),
    ].where((t) => t.isNotEmpty).toList();
    // Potpis "— Ime (@nalog) datum" ide posebno, sitnije.
    var footer = '';
    if (paragraphs.length > 1 && _isSignature(paragraphs.last)) {
      footer = paragraphs.removeLast();
    }
    if (paragraphs.isEmpty) {
      paragraphs = [_cleanTweet(element.text as String)];
    }
    if (footer.isEmpty) {
      // Potpis je ponekad van pasusa, odmah u blockquote.
      final all = (element.text as String).trim();
      final i = all.lastIndexOf('—');
      if (i > 0) footer = all.substring(i).trim();
      if (footer.isNotEmpty && paragraphs.last.contains(footer)) footer = '';
    }
    final links = <String>[
      for (final a in element.querySelectorAll('a') as Iterable)
        (a.attributes['href'] ?? '').toString(),
    ];
    final url = links.lastWhere(
      (h) => h.contains('/status/'),
      orElse: () => links.isNotEmpty ? links.last : '',
    );
    var tweetHtml = element.outerHtml as String;
    if (dark) {
      tweetHtml = tweetHtml.replaceFirst('<blockquote', '<blockquote data-theme="dark"');
    }
    return LiveEmbed(
      embedHtml: tweetHtml,
      scriptUrl: 'https://platform.twitter.com/widgets.js',
      dark: dark,
      fallback: EmbedCard(
      badge: const _XBadge(),
      label: 'Objava na X',
      text: paragraphs.join('\n\n'),
      footer: footer,
      url: url,
      buttonText: 'Otvori objavu na X',
      ),
    );
  }

  // Instagram
  if (tag == 'blockquote' && classes.contains('instagram-media')) {
    var url = (attrs['data-instgrm-permalink'] ?? '').toString();
    if (url.isEmpty) url = _firstLink(element, 'instagram.com');
    // Ispod objave Instagram piše "A post shared by Ime (@nalog)".
    var footer = '';
    for (final p in element.querySelectorAll('p') as Iterable) {
      final t = (p.text as String).replaceAll(RegExp(r'\s+'), ' ').trim();
      if (t.contains('@') || t.toLowerCase().contains('shared by')) {
        footer = t;
      }
    }
    final handle = RegExp(r'\(@([\w.]+)\)').firstMatch(footer)?.group(1) ??
        RegExp(r'instagram\.com/([\w.]+)/?(?:\?|$)').firstMatch(url)?.group(1);
    return LiveEmbed(
      embedHtml: element.outerHtml as String,
      scriptUrl: 'https://www.instagram.com/embed.js',
      dark: dark,
      fallback: EmbedCard(
      badge: const _IconBadge(
        icon: Icons.camera_alt_outlined,
        color: Color(0xFFD62976),
      ),
      label: handle != null ? 'Objava na Instagramu · @$handle' : 'Objava na Instagramu',
      text: '',
      footer: handle == null ? footer : '',
      url: url,
      buttonText: 'Otvori objavu na Instagramu',
      ),
    );
  }

  // TikTok
  if (tag == 'blockquote' && classes.contains('tiktok-embed')) {
    var url = (attrs['cite'] ?? '').toString();
    if (url.isEmpty) url = _firstLink(element, 'tiktok.com');
    return LiveEmbed(
      embedHtml: element.outerHtml as String,
      scriptUrl: 'https://www.tiktok.com/embed.js',
      dark: dark,
      fallback: EmbedCard(
      badge: const _IconBadge(icon: Icons.music_note, color: Colors.black),
      label: 'Snimak na TikToku',
      text: '',
      url: url,
      buttonText: 'Otvori na TikToku',
      ),
    );
  }

  // YouTube
  if (tag == 'iframe') {
    final src = (attrs['src'] ?? attrs['data-src'] ?? '').toString();
    final id = RegExp(r'(?:youtube(?:-nocookie)?\.com/embed/|youtu\.be/|[?&]v=)([\w-]{11})')
        .firstMatch(src)
        ?.group(1);
    if (id != null) {
      return LiveEmbed(
        embedHtml: '<iframe src="https://www.youtube.com/embed/$id?playsinline=1&rel=0" '
            'allow="accelerometer; autoplay; clipboard-write; encrypted-media; '
            'gyroscope; picture-in-picture; fullscreen" allowfullscreen '
            'referrerpolicy="strict-origin-when-cross-origin"></iframe>',
        aspectRatio: 16 / 9,
        dark: dark,
        fallback: YouTubeCard(videoId: id),
      );
    }
  }

  return null;
}

/// Uklanja skraćene linkove (t.co, pic.twitter.com) iz teksta objave.
String _cleanTweet(String text) => text
    .replaceAll(RegExp(r'(https?://)?t\.co/\S+'), '')
    .replaceAll(RegExp(r'pic\.twitter\.com/\S+'), '')
    .replaceAll(RegExp(r'[ \t]+\n'), '\n')
    .trim();

bool _isSignature(String t) =>
    t.startsWith('—') || t.startsWith('–') || t.startsWith('- ');

/// Emotikoni i sitne ikonice u tekstu ostaju kakvi jesu.
bool _isTinyImage(dynamic img) {
  final Map a = img.attributes as Map;
  final cls = (a['class'] ?? '').toString();
  final src = (a['src'] ?? '').toString();
  if (cls.contains('emoji') || src.contains('s.w.org')) return true;
  final w = int.tryParse((a['width'] ?? '').toString());
  return w != null && w < 120;
}

String _imgSrc(dynamic img) {
  final Map a = img.attributes as Map;
  for (final k in ['data-src', 'data-lazy-src', 'src']) {
    final v = (a[k] ?? '').toString();
    if (v.startsWith('http')) return v;
  }
  return (a['src'] ?? '').toString();
}

double? _imgAspect(dynamic img) {
  final Map a = img.attributes as Map;
  final w = double.tryParse((a['width'] ?? '').toString());
  final h = double.tryParse((a['height'] ?? '').toString());
  if (w == null || h == null || w <= 0 || h <= 0) return null;
  return w / h;
}

String _firstLink(dynamic element, String host) {
  for (final a in element.querySelectorAll('a') as Iterable) {
    final href = (a.attributes['href'] ?? '').toString();
    if (href.contains(host)) return href;
  }
  return '';
}

/// Kartica za objavu sa društvene mreže.
class EmbedCard extends StatelessWidget {
  final Widget badge;
  final String label;
  final String text;
  final String footer;
  final String url;
  final String buttonText;

  const EmbedCard({
    super.key,
    required this.badge,
    required this.label,
    required this.text,
    this.footer = '',
    required this.url,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: context.bg,
        border: Border.all(color: context.line, width: 1.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              badge,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.ink,
                  ),
                ),
              ),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              text,
              style: TextStyle(fontSize: 16, height: 1.45, color: context.ink),
            ),
          ],
          if (footer.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              footer,
              style: TextStyle(fontSize: 13, height: 1.4, color: context.muted),
            ),
          ],
          if (url.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppConfig.brandTextColor,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                ),
                onPressed: () => openLink(context, url),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(
                  buttonText,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            )
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }
}

/// YouTube snimak: slika snimka sa dugmetom za puštanje.
class YouTubeCard extends StatelessWidget {
  final String videoId;
  const YouTubeCard({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: () =>
            openLink(context, 'https://www.youtube.com/watch?v=$videoId'),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              NetImage(
                url: 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                radius: BorderRadius.circular(8),
              ),
              Center(
                child: Container(
                  width: 68,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _XBadge extends StatelessWidget {
  const _XBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'X',
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }
}

/// Slika iz teksta vesti: puna širina, dodir je otvara preko celog ekrana.
class ContentImage extends StatelessWidget {
  final String url;
  final double? aspect;
  const ContentImage({super.key, required this.url, this.aspect});

  @override
  Widget build(BuildContext context) {
    final image = aspect != null
        ? AspectRatio(
            aspectRatio: aspect!,
            child: NetImage(url: url, radius: BorderRadius.circular(6)),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              url,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          );
    return GestureDetector(
      onTap: () => openImage(context, url),
      child: SizedBox(width: double.infinity, child: image),
    );
  }
}
