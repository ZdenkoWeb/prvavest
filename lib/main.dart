import 'package:flutter/material.dart';

import 'api.dart';
import 'config.dart';
import 'header.dart';
import 'models.dart';
import 'saved_store.dart';
import 'screens/categories_screen.dart';
import 'screens/home_screen.dart';
import 'screens/saved_screen.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SavedStore.instance.load();
  await ThemeController.instance.load();
  runApp(const PrvaVestApp());
}

class PrvaVestApp extends StatelessWidget {
  const PrvaVestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) => MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: mode,
        home: const HomeShell(),
      ),
    );
  }
}

/// Glavni ekran: zaglavlje gore, sadržaj u sredini, donji meni
/// (Naslovna, Najnovije, Kategorije, Sačuvano) kao na sajtu.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Dugme "nazad" na telefonu prvo vraća na Naslovnu.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        drawer: const _AppDrawer(),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SiteHeader(),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: const [
                    HomeScreen(),
                    LatestScreen(),
                    CategoriesScreen(),
                    SavedScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _BottomMenu(
          index: _index,
          onSelect: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

class _BottomMenu extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  const _BottomMenu({required this.index, required this.onSelect});

  static const _items = [
    (Icons.article_outlined, 'Naslovna'),
    (Icons.schedule, 'Najnovije'),
    (Icons.grid_view, 'Kategorije'),
    (Icons.bookmark_border, 'Sačuvano'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  child: InkWell(
                    onTap: () => onSelect(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _items[i].$1,
                          size: 27,
                          color: i == index
                              ? AppConfig.brandColor
                              : context.ink,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _items[i].$2,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: i == index
                                ? AppConfig.brandColor
                                : context.ink,
                          ),
                        ),
                      ],
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

/// Bočni meni (narandžasto dugme gore levo): sve rubrike.
class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: PrvaVestLogo(height: 26),
            ),
            Container(height: 4, color: context.box),
            Expanded(
              child: FutureBuilder<List<Category>>(
                future: WordPressApi.instance.categories(),
                builder: (context, snap) {
                  final cats = snap.data ?? const <Category>[];
                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      for (final c in cats)
                        ListTile(
                          title: Text(
                            chipLabel(c),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: c.slug == AppConfig.highlightedSlug
                                  ? AppConfig.brandTextColor
                                  : context.ink,
                            ),
                          ),
                          onTap: () {
                            Scaffold.of(context).closeDrawer();
                            openCategory(context, c);
                          },
                        ),
                      if (cats.isEmpty &&
                          snap.connectionState != ConnectionState.done)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      Divider(color: context.line),
                      ListTile(
                        leading: Icon(Icons.search, color: context.ink),
                        title: Text(
                          'Pretraga',
                          style: TextStyle(color: context.ink),
                        ),
                        onTap: () {
                          Scaffold.of(context).closeDrawer();
                          openSearch(context);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.public, color: context.ink),
                        title: Text(
                          'Otvori prvavest.com',
                          style: TextStyle(color: context.ink),
                        ),
                        onTap: () => openLink(context, AppConfig.siteUrl),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
