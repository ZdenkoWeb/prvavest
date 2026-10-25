import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'api.dart';
import 'config.dart';
import 'models.dart';
import 'nav.dart';
import 'theme.dart';
import 'widgets.dart';

/// Zaglavlje kao na sajtu: narandžasta traka NAJNOVIJE, red sa
/// menijem, logom, pretragom i suncem, pa trake sa kategorijama.
class SiteHeader extends StatelessWidget {
  /// Ako je zadato, umesto menija levo stoji strelica nazad.
  final VoidCallback? onBack;
  final bool showTicker;
  final bool showChips;

  const SiteHeader({
    super.key,
    this.onBack,
    this.showTicker = true,
    this.showChips = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTicker) const NewsTicker(),
          _TopBar(onBack: onBack),
          Divider(height: 1, thickness: 1, color: context.line),
          if (showChips) const CategoryChips(),
          Container(height: 4, color: context.box),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback? onBack;
  const _TopBar({this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return SizedBox(
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: _OrangeSquareButton(
                icon: onBack != null ? Icons.arrow_back : Icons.notes,
                tooltip: onBack != null ? 'Nazad' : 'Meni',
                onTap: onBack ?? () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          // Dodir na logo vraća na Naslovnu, kao na sajtu.
          Semantics(
            button: true,
            label: 'Naslovna',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                homeTab.value = 0;
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: PrvaVestLogo(height: 21),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Pretraga',
                    icon: Icon(Icons.search, size: 28, color: context.ink),
                    onPressed: () => openSearch(context),
                  ),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: theme,
                    builder: (context, mode, _) => IconButton(
                      tooltip: mode == ThemeMode.dark
                          ? 'Svetla tema'
                          : 'Tamna tema',
                      icon: Icon(
                        mode == ThemeMode.dark
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        size: 28,
                        color: context.ink,
                      ),
                      onPressed: theme.toggle,
                    ),
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

class _OrangeSquareButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _OrangeSquareButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppConfig.brandColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

/// Traka sa kategorijama: #Izbori2026 u narandžastom, ostale velikim slovima.
class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FutureBuilder<List<Category>>(
        future: WordPressApi.instance.categories(),
        builder: (context, snap) {
          final cats = snap.data ?? const <Category>[];
          if (cats.isEmpty) return const SizedBox.shrink();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            itemCount: cats.length,
            separatorBuilder: (_, _) => const SizedBox(width: 2),
            itemBuilder: (context, i) => _CategoryChip(category: cats[i]),
          );
        },
      ),
    );
  }
}

/// Jedna kategorija u traci. Poseban widget, da bi boja teksta
/// sigurno pratila svetlu/tamnu temu.
class _CategoryChip extends StatelessWidget {
  final Category category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final highlighted = category.slug == AppConfig.highlightedSlug;
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => openCategory(context, category),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: highlighted
              ? BoxDecoration(
                  color: AppConfig.brandColor,
                  borderRadius: BorderRadius.circular(20),
                )
              : null,
          child: Text(
            chipLabel(category),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: highlighted ? Colors.white : context.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Narandžasta traka "NAJNOVIJE:" sa naslovima koji klize.
class NewsTicker extends StatefulWidget {
  const NewsTicker({super.key});

  @override
  State<NewsTicker> createState() => _NewsTickerState();
}

class _NewsTickerState extends State<NewsTicker>
    with SingleTickerProviderStateMixin {
  static const _speed = 45.0; // tačaka u sekundi

  final _scroll = ScrollController();
  late final Ticker _ticker;
  List<Post> _posts = const [];
  Duration _last = Duration.zero;
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _load();
  }

  Future<void> _load() async {
    try {
      final posts = await WordPressApi.instance.latest();
      if (!mounted || posts.isEmpty) return;
      setState(() => _posts = posts.take(10).toList());
      if (!_ticker.isActive) _ticker.start();
    } catch (_) {
      // Bez interneta traka ostaje prazna, ostatak aplikacije radi.
    }
  }

  void _tick(Duration elapsed) {
    var dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt < 0 || dt > 0.1) dt = 0.016;
    if (!_scroll.hasClients) return;
    _offset += dt * _speed;
    _scroll.jumpTo(_offset);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    return Container(
      height: 40,
      color: AppConfig.brandColor,
      child: Row(
        children: [
          Container(
            color: AppConfig.brandDark,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: white.withAlpha(170),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'NAJNOVIJE:',
                  style: TextStyle(
                    color: white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _posts.isEmpty
                ? const SizedBox.shrink()
                : ListView.builder(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, i) {
                      final p = _posts[i % _posts.length];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => openArticle(context, p),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.title,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: white.withAlpha(45),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  relativeLabel(p.date),
                                  style: const TextStyle(
                                    color: white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: white.withAlpha(150),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
