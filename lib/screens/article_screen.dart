import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models.dart';
import '../saved_store.dart';
import '../widgets.dart';

/// Ekran za čitanje jedne vesti.
class ArticleScreen extends StatelessWidget {
  final Post post;
  const ArticleScreen({super.key, required this.post});

  Future<void> _openInBrowser(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link ne može da se otvori.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = SavedStore.instance;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const PrvaVestLogo(height: 26),
        actions: [
          ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              final saved = store.isSaved(post.id);
              return IconButton(
                tooltip: saved ? 'Ukloni iz sačuvanih' : 'Sačuvaj vest',
                icon: Icon(
                  saved ? Icons.bookmark : Icons.bookmark_border,
                  color: saved ? AppConfig.brandColor : null,
                ),
                onPressed: () {
                  store.toggle(post);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text(saved
                          ? 'Vest je uklonjena iz sačuvanih.'
                          : 'Vest je sačuvana.'),
                      duration: const Duration(seconds: 2),
                    ));
                },
              );
            },
          ),
          IconButton(
            tooltip: 'Otvori na sajtu',
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => _openInBrowser(context, post.link),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryLabel(post.category, size: 12),
                const SizedBox(height: 8),
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 25,
                    height: 1.22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  [post.author, post.dateLabel]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          if (post.imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: NetImage(url: post.imageUrl),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: HtmlWidget(
              post.content,
              textStyle: const TextStyle(fontSize: 17, height: 1.6),
              onTapUrl: (url) async {
                await _openInBrowser(context, url);
                return true;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: OutlinedButton.icon(
              onPressed: () => _openInBrowser(context, post.link),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Pročitaj na prvavest.com'),
            ),
          ),
        ],
      ),
    );
  }
}
