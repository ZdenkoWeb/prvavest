import 'package:flutter/material.dart';

import 'api.dart';
import 'config.dart';
import 'header.dart';
import 'models.dart';
import 'nav.dart';
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
  await TextSizeController.instance.load();
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
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: homeTab,
      builder: (context, index, _) => PopScope(
        // Dugme "nazad" na telefonu prvo vraća na Naslovnu.
        canPop: index == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) homeTab.value = 0;
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
                    index: index,
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
          bottomNavigationBar: const AppBottomMenu(),
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
