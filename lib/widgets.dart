import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'config.dart';
import 'models.dart';
import 'screens/article_screen.dart';

/// Logo Prve Vesti sa sajta. Ako ne može da se učita,
/// prikazuje se natpis u bojama sajta.
class PrvaVestLogo extends StatelessWidget {
  final double height;
  const PrvaVestLogo({super.key, this.height = 30});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: AppConfig.logoUrl,
      height: height,
      fit: BoxFit.contain,
      placeholder: (_, __) => SizedBox(height: height),
      errorWidget: (_, __, ___) => _TextLogo(height: height),
    );
  }
}

class _TextLogo extends StatelessWidget {
  final double height;
  const _TextLogo({required this.height});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: height * 0.55,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        color: AppConfig.brandColor,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text('PRVA', style: style.copyWith(color: Colors.white)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text('VEST', style: style),
      ),
    ]);
  }
}

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
      color: const Color(0xFFE4E2DD),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: Color(0xFF9A978F)),
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

/// Mala crvena oznaka kategorije iznad naslova.
class CategoryLabel extends StatelessWidget {
  final String text;
  final double size;
  const CategoryLabel(this.text, {super.key, this.size = 11});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppConfig.brandColor,
      ),
    );
  }
}

void openArticle(BuildContext context, Post post) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ArticleScreen(post: post)),
  );
}

/// Velika kartica za glavnu vest na vrhu liste.
class FeaturedPostCard extends StatelessWidget {
  final Post post;
  const FeaturedPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openArticle(context, post),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: NetImage(url: post.imageUrl),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryLabel(post.category, size: 12),
                  const SizedBox(height: 6),
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 21,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    [post.author, post.dateLabel]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
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

/// Manja kartica: slika levo, naslov desno.
class PostTile extends StatelessWidget {
  final Post post;
  const PostTile({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openArticle(context, post),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NetImage(
                url: post.imageUrl,
                width: 104,
                height: 78,
                radius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryLabel(post.category),
                    const SizedBox(height: 4),
                    Text(
                      post.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.dateLabel,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.black45),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Pokušaj ponovo')),
          ],
        ),
      ),
    );
  }
}
