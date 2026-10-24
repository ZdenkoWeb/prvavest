import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../api.dart';
import '../config.dart';
import '../embeds.dart';
import '../header.dart';
import '../models.dart';
import '../nav.dart';
import '../theme.dart';
import '../widgets.dart';
import 'image_viewer.dart';

/// Ekran za čitanje jedne vesti, uređen kao stranica vesti na sajtu.
class ArticleScreen extends StatelessWidget {
  final Post post;
  const ArticleScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final ink = context.ink;
    return Scaffold(
      bottomNavigationBar: const AppBottomMenu(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SiteHeader(
              onBack: () => Navigator.of(context).pop(),
              showChips: false,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  Row(
                    children: [
                      Expanded(child: CategoryLabel(post.category, size: 15)),
                      const _TextSizeButtons(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    post.title,
                    style: TextStyle(
                      fontFamily: kSerif,
                      fontSize: 29,
                      height: 1.17,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ShareBar(post: post),
                  const SizedBox(height: 18),
                  _Byline(post: post),
                  const SizedBox(height: 20),
                  if (post.imageUrl != null) ...[
                    GestureDetector(
                      onTap: () => openImage(context, post.imageUrl),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            NetImage(
                              url: post.imageUrl,
                              radius: BorderRadius.circular(6),
                            ),
                            const Positioned(
                              right: 10,
                              bottom: 10,
                              child: _ZoomHint(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  ValueListenableBuilder<double>(
                    valueListenable: TextSizeController.instance,
                    builder: (context, scale, _) => HtmlWidget(
                    post.content,
                    textStyle: TextStyle(
                      fontFamily: kSerif,
                      fontSize: 18 * scale,
                      height: 1.65,
                      color: ink,
                    ),
                    // Dodir na sliku u tekstu otvara je preko celog ekrana.
                    onTapImage: (image) => openImage(
                      context,
                      image.sources.isNotEmpty ? image.sources.first.url : null,
                    ),
                    // Objave sa X-a, Instagrama, TikToka i YouTube snimci.
                    customWidgetBuilder: (element) =>
                        buildEmbed(context, element),
                    customStylesBuilder: (element) {
                      switch (element.localName) {
                        case 'h1':
                        case 'h2':
                          return {
                            'font-size': '${(22 * scale).round()}px',
                            'line-height': '1.3',
                            'font-weight': '800',
                            'margin': '10px 0',
                          };
                        case 'h3':
                        case 'h4':
                          return {
                            'font-size': '${(19 * scale).round()}px',
                            'line-height': '1.35',
                            'font-weight': '700',
                          };
                        case 'a':
                          return {
                            'color': '#E05A14',
                            'text-decoration': 'none',
                          };
                        case 'blockquote':
                          return {
                            'border-left': '3px solid #F26A1F',
                            'padding-left': '14px',
                            'margin': '12px 0',
                            'font-style': 'italic',
                          };
                        case 'figcaption':
                          return {'font-size': '13px', 'color': '#9A9AA0'};
                      }
                      return null;
                    },
                    onTapUrl: (url) async {
                      await openLink(context, url);
                      return true;
                    },
                  ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(width: 70, height: 4, color: ink),
                  ),
                  if (post.tags.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _Tags(tags: post.tags),
                  ],
                  const SizedBox(height: 26),
                  Divider(height: 1, color: context.line),
                  const SizedBox(height: 18),
                  ShareBar(post: post),
                  const SizedBox(height: 18),
                  Divider(height: 1, color: context.line),
                  const SizedBox(height: 22),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConfig.brandTextColor,
                      side: const BorderSide(
                        color: AppConfig.brandColor,
                        width: 1.4,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: () => openLink(context, '${post.link}#comments'),
                    icon: const Icon(Icons.forum_outlined),
                    label: const Text(
                      'Komentari na prvavest.com',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _RelatedPosts(post: post),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Autor, dugme "Sačuvaj" i vreme objave.
class _Byline extends StatelessWidget {
  final Post post;
  const _Byline({required this.post});

  @override
  Widget build(BuildContext context) {
    final ink = context.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const OneVMark(size: 13, oneColor: Colors.white),
            ),
            if (post.author.isNotEmpty)
              Text(
                post.author,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ink,
                  decoration: TextDecoration.underline,
                  decorationColor: ink,
                ),
              ),
            Text('//', style: TextStyle(color: context.muted)),
            SaveChip(post: post),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Objavljeno: ${formatDateTime(post.date)}',
          style: TextStyle(fontSize: 14, color: ink),
        ),
        if (post.modified != null &&
            post.modified!.difference(post.date).inMinutes > 5)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Poslednje ažurirano: ${formatDateTime(post.modified!)}',
              style: TextStyle(fontSize: 14, color: context.muted),
            ),
          ),
      ],
    );
  }
}

/// "OZNAČENO: Albert Rijera, Crvena zvezda, ..." – dodir otvara pretragu.
class _Tags extends StatelessWidget {
  final List<String> tags;
  const _Tags({required this.tags});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: kSerif,
      fontSize: 18,
      height: 1.6,
      fontWeight: FontWeight.w800,
      color: context.ink,
    );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 2,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sell_outlined, size: 20, color: context.muted),
              const SizedBox(width: 6),
              Text(
                'OZNAČENO:',
                style: TextStyle(
                  fontSize: 16,
                  letterSpacing: 0.6,
                  color: context.muted,
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < tags.length; i++)
          InkWell(
            onTap: () => openSearch(context, query: tags[i]),
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                i < tags.length - 1 ? '${tags[i]},' : tags[i],
                style: style,
              ),
            ),
          ),
      ],
    );
  }
}

/// Siva traka sa dugmićima za deljenje (Facebook, X, WhatsApp...).
class ShareBar extends StatelessWidget {
  final Post post;
  const ShareBar({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final url = Uri.encodeComponent(post.link);
    final text = Uri.encodeComponent(post.title);
    final both = Uri.encodeComponent('${post.title} ${post.link}');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.box,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.share_outlined, color: context.muted),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ShareButton(
                    tooltip: 'Podeli na Facebooku',
                    child: Icon(Icons.facebook, color: context.ink),
                    onTap: () => openLink(
                      context,
                      'https://www.facebook.com/sharer/sharer.php?u=$url',
                    ),
                  ),
                  _ShareButton(
                    tooltip: 'Podeli na X',
                    child: Text(
                      'X',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: context.ink,
                      ),
                    ),
                    onTap: () => openLink(
                      context,
                      'https://twitter.com/intent/tweet?url=$url&text=$text',
                    ),
                  ),
                  _ShareButton(
                    tooltip: 'Pošalji na WhatsApp',
                    child: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
                    onTap: () =>
                        openLink(context, 'https://wa.me/?text=$both'),
                  ),
                  _ShareButton(
                    tooltip: 'Pošalji na Viber',
                    child: const Icon(
                      Icons.phone_in_talk_outlined,
                      color: Color(0xFF7360F2),
                    ),
                    onTap: () =>
                        openLink(context, 'viber://forward?text=$both'),
                  ),
                  _ShareButton(
                    tooltip: 'Pošalji na Telegram',
                    child: Icon(Icons.telegram, color: context.ink),
                    onTap: () => openLink(
                      context,
                      'https://t.me/share/url?url=$url&text=$text',
                    ),
                  ),
                  _ShareButton(
                    tooltip: 'Kopiraj link',
                    child: Icon(Icons.link, color: context.ink),
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: post.link));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(const SnackBar(
                          content: Text('Link je kopiran.'),
                          duration: Duration(seconds: 2),
                        ));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final String tooltip;
  final Widget child;
  final VoidCallback onTap;
  const _ShareButton({
    required this.tooltip,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(width: 44, height: 40, child: Center(child: child)),
      ),
    );
  }
}

/// Dugmad A− i A+ za veličinu slova u tekstu vesti.
class _TextSizeButtons extends StatelessWidget {
  const _TextSizeButtons();

  @override
  Widget build(BuildContext context) {
    final ctrl = TextSizeController.instance;
    return ValueListenableBuilder<double>(
      valueListenable: ctrl,
      builder: (context, _, __) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: context.line, width: 1.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SizeButton(
              label: 'A−',
              fontSize: 14,
              tooltip: 'Manja slova',
              onTap: ctrl.canShrink ? () => ctrl.change(-TextSizeController.step) : null,
            ),
            Container(width: 1.4, height: 22, color: context.line),
            _SizeButton(
              label: 'A+',
              fontSize: 18,
              tooltip: 'Veća slova',
              onTap: ctrl.canGrow ? () => ctrl.change(TextSizeController.step) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SizeButton extends StatelessWidget {
  final String label;
  final double fontSize;
  final String tooltip;
  final VoidCallback? onTap;
  const _SizeButton({
    required this.label,
    required this.fontSize,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 36,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: kSerif,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: onTap == null ? context.line : context.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mala ikonica lupe na glavnoj slici (znak da se slika može uvećati).
class _ZoomHint extends StatelessWidget {
  const _ZoomHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(110),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.zoom_in, color: Colors.white, size: 20),
    );
  }
}

/// "Pročitajte još": nekoliko vesti iz iste rubrike.
class _RelatedPosts extends StatefulWidget {
  final Post post;
  const _RelatedPosts({required this.post});

  @override
  State<_RelatedPosts> createState() => _RelatedPostsState();
}

class _RelatedPostsState extends State<_RelatedPosts> {
  late final Future<List<Post>> _future = WordPressApi.instance
      .fetchPosts(categoryId: widget.post.categoryId, perPage: 6)
      .then((posts) =>
          posts.where((p) => p.id != widget.post.id).take(4).toList());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: _future,
      builder: (context, snap) {
        final posts = snap.data ?? const <Post>[];
        if (posts.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 34),
            Text(
              'Pročitajte još',
              style: TextStyle(
                fontFamily: kSerif,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: context.ink,
              ),
            ),
            const SizedBox(height: 8),
            Container(width: 44, height: 3, color: AppConfig.brandColor),
            const SizedBox(height: 4),
            for (var i = 0; i < posts.length; i++) ...[
              RowPost(post: posts[i]),
              if (i < posts.length - 1)
                Divider(height: 1, thickness: 1, color: context.line),
            ],
          ],
        );
      },
    );
  }
}
