import 'package:flutter/material.dart';

import 'config.dart';
import 'theme.dart';
import 'widgets.dart';

/// Objave sa X-a (Twittera), Instagrama, TikToka i YouTube snimci
/// u tekstu vesti. Na sajtu ih prikazuje JavaScript, koji aplikacija
/// ne pokreće, pa ih ovde crtamo kao kartice sa tekstom i linkom.
///
/// `element` je HTML element iz teksta vesti. Vraća null za sve
/// ostalo, pa se taj deo prikazuje normalno.
Widget? buildEmbed(BuildContext context, dynamic element) {
  final String tag = element.localName ?? '';
  final Set<String> classes = Set<String>.from(element.classes as Iterable);
  final Map attrs = element.attributes as Map;

  // X / Twitter
  if (tag == 'blockquote' && classes.contains('twitter-tweet')) {
    final paragraphs = <String>[
      for (final p in element.querySelectorAll('p') as Iterable)
        (p.text as String).trim(),
    ].where((t) => t.isNotEmpty).toList();
    final links = <String>[
      for (final a in element.querySelectorAll('a') as Iterable)
        (a.attributes['href'] ?? '').toString(),
    ];
    final url = links.lastWhere(
      (h) => h.contains('/status/'),
      orElse: () => links.isNotEmpty ? links.last : '',
    );
    return EmbedCard(
      badge: const _XBadge(),
      label: 'Objava na X',
      text: paragraphs.isEmpty
          ? (element.text as String).trim()
          : paragraphs.join('\n\n'),
      url: url,
      buttonText: 'Otvori objavu na X',
    );
  }

  // Instagram
  if (tag == 'blockquote' && classes.contains('instagram-media')) {
    var url = (attrs['data-instgrm-permalink'] ?? '').toString();
    if (url.isEmpty) url = _firstLink(element, 'instagram.com');
    return EmbedCard(
      badge: const _IconBadge(
        icon: Icons.camera_alt_outlined,
        color: Color(0xFFD62976),
      ),
      label: 'Objava na Instagramu',
      text: '',
      url: url,
      buttonText: 'Otvori objavu na Instagramu',
    );
  }

  // TikTok
  if (tag == 'blockquote' && classes.contains('tiktok-embed')) {
    var url = (attrs['cite'] ?? '').toString();
    if (url.isEmpty) url = _firstLink(element, 'tiktok.com');
    return EmbedCard(
      badge: const _IconBadge(icon: Icons.music_note, color: Colors.black),
      label: 'Snimak na TikToku',
      text: '',
      url: url,
      buttonText: 'Otvori na TikToku',
    );
  }

  // YouTube
  if (tag == 'iframe') {
    final src = (attrs['src'] ?? attrs['data-src'] ?? '').toString();
    final id = RegExp(r'(?:youtube(?:-nocookie)?\.com/embed/|youtu\.be/|[?&]v=)([\w-]{11})')
        .firstMatch(src)
        ?.group(1);
    if (id != null) return YouTubeCard(videoId: id);
  }

  return null;
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
  final String url;
  final String buttonText;

  const EmbedCard({
    super.key,
    required this.badge,
    required this.label,
    required this.text,
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.ink,
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
