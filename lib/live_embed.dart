import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'widgets.dart';

/// Prava objava sa X-a, Instagrama ili TikToka, ili YouTube snimak,
/// prikazana unutar teksta vesti isto kao na sajtu (video se pušta
/// u aplikaciji). Ako se objava ne učita, prikazuje se [fallback].
class LiveEmbed extends StatefulWidget {
  /// HTML objave (npr. <blockquote class="twitter-tweet">...).
  final String embedHtml;

  /// Skripta koja od HTML-a pravi pravu objavu (widgets.js...).
  final String? scriptUrl;

  /// Za YouTube: fiksni odnos širine i visine (16:9).
  final double? aspectRatio;

  final bool dark;
  final Widget fallback;

  const LiveEmbed({
    super.key,
    required this.embedHtml,
    this.scriptUrl,
    this.aspectRatio,
    this.dark = false,
    required this.fallback,
  });

  @override
  State<LiveEmbed> createState() => _LiveEmbedState();
}

class _LiveEmbedState extends State<LiveEmbed> {
  static const _base = 'https://prvavest.com/';

  late final WebViewController _controller;
  double _height = 220;
  bool _measured = false;
  bool _failed = false;
  Timer? _giveUp;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'PVHeight',
        onMessageReceived: (m) {
          final h = double.tryParse(m.message);
          if (h == null || h < 40 || !mounted) return;
          if (!_measured || (h - _height).abs() > 2) {
            setState(() {
              _height = h;
              _measured = true;
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            // Delovi objave (slike, video) se učitavaju normalno.
            if (!request.isMainFrame ||
                url == _base ||
                url.startsWith('about:') ||
                url.startsWith('data:')) {
              return NavigationDecision.navigate;
            }
            // Dodir na link u objavi otvara X / Instagram / YouTube.
            openLink(context, url);
            return NavigationDecision.prevent;
          },
          onWebResourceError: (error) {
            if ((error.isForMainFrame ?? false) && mounted) {
              setState(() => _failed = true);
            }
          },
        ),
      )
      ..loadHtmlString(_page(), baseUrl: _base);

    // Ako se objava ne pojavi za 15 sekundi (nema interneta, obrisana
    // objava), prikazujemo karticu sa linkom.
    if (widget.aspectRatio == null) {
      _giveUp = Timer(const Duration(seconds: 15), () {
        if (mounted && !_measured) setState(() => _failed = true);
      });
    }
  }

  @override
  void dispose() {
    _giveUp?.cancel();
    super.dispose();
  }

  String _page() {
    final bg = widget.dark ? '#0F0F12' : '#FFFFFF';
    final fg = widget.dark ? '#F1F1F3' : '#141938';
    final script = widget.scriptUrl == null
        ? ''
        : '<script async src="${widget.scriptUrl}" charset="utf-8"></script>';
    final fill = widget.aspectRatio != null;
    return '''<!DOCTYPE html>
<html><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  html, body { margin: 0; padding: 0; background: $bg; color: $fg;
    font-family: sans-serif; ${fill ? 'height: 100%;' : ''} }
  #pv { ${fill ? 'height: 100%;' : 'padding: 1px 0;'} }
  #pv > * { margin-left: auto !important; margin-right: auto !important; }
  iframe { max-width: 100%; }
  ${fill ? '#pv iframe { width: 100%; height: 100%; border: 0; }' : ''}
  blockquote { margin: 8px 0; }
  a { color: #E05A14; }
</style>
</head><body>
<div id="pv">${widget.embedHtml}</div>
$script
<script>
  function pvh() {
    try {
      var el = document.getElementById('pv');
      PVHeight.postMessage(String(Math.ceil(el.getBoundingClientRect().height)));
    } catch (e) {}
  }
  window.addEventListener('load', pvh);
  setInterval(pvh, 600);
  if (window.ResizeObserver) new ResizeObserver(pvh).observe(document.getElementById('pv'));
</script>
</body></html>''';
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.fallback;

    final view = WebViewWidget(controller: _controller);

    if (widget.aspectRatio != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(aspectRatio: widget.aspectRatio!, child: view),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: _height,
          child: Stack(
            children: [
              Positioned.fill(child: view),
              if (!_measured)
                const Positioned.fill(
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
