import 'package:flutter/material.dart';

import 'config.dart';
import 'theme.dart';

/// Koja je stavka donjeg menija izabrana (0 Naslovna, 1 Najnovije,
/// 2 Kategorije, 3 Sačuvano). Deli se između svih ekrana.
final ValueNotifier<int> homeTab = ValueNotifier<int>(0);

/// Signal za osvežavanje: menja se kad se aplikacija vrati iz pozadine
/// posle par minuta i na svakih 5 minuta dok je otvorena. Traka
/// NAJNOVIJE, Naslovna i liste vesti tada same učitaju nove vesti.
final ValueNotifier<int> appRefresh = ValueNotifier<int>(0);

/// Donji meni koji stoji na svakom ekranu. Sa ekrana vesti ili
/// rubrike dodir na stavku vraća na glavni ekran i otvara tu stavku.
class AppBottomMenu extends StatelessWidget {
  const AppBottomMenu({super.key});

  static const _items = [
    (Icons.article_outlined, 'Naslovna'),
    (Icons.schedule, 'Najnovije'),
    (Icons.grid_view, 'Kategorije'),
    (Icons.bookmark_border, 'Sačuvano'),
  ];

  void _select(BuildContext context, int i) {
    homeTab.value = i;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: homeTab,
      builder: (context, index, _) => Container(
        decoration: BoxDecoration(
          color: context.bg,
          border: Border(top: BorderSide(color: context.line)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _MenuItem(
                      icon: _items[i].$1,
                      label: _items[i].$2,
                      selected: i == index,
                      onTap: () => _select(context, i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppConfig.brandColor : context.ink;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 27, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
