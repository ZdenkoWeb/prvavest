import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Otvara sliku preko celog ekrana.
void openImage(BuildContext context, String? url) {
  if (url == null || url.isEmpty) return;
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => ImageViewer(url: url),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Slika preko celog ekrana: uvećava se sa dva prsta ili
/// dvostrukim dodirom, a zatvara dugmetom X ili dugmetom nazad.
class ImageViewer extends StatefulWidget {
  final String url;
  const ImageViewer({super.key, required this.url});

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  final _controller = TransformationController();
  TapDownDetails? _doubleTapAt;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    if (_controller.value.getMaxScaleOnAxis() > 1.01) {
      _controller.value = Matrix4.identity();
      return;
    }
    final p = _doubleTapAt?.localPosition ?? Offset.zero;
    const scale = 2.5;
    _controller.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(-p.dx * (scale - 1), -p.dy * (scale - 1), 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onDoubleTapDown: (d) => _doubleTapAt = d,
              onDoubleTap: _toggleZoom,
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.url,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  tooltip: 'Zatvori',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white24,
                  ),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
