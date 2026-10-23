import 'package:flutter/material.dart';

import 'config.dart';
import 'saved_store.dart';
import 'screens/home_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/search_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SavedStore.instance.load();
  runApp(const PrvaVestApp());
}

class PrvaVestApp extends StatelessWidget {
  const PrvaVestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppConfig.brandColor,
      primary: AppConfig.brandColor,
    );
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF4F3F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF15171A),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Color(0xFF15171A),
          unselectedLabelColor: Color(0xFF5F6368),
          indicatorColor: AppConfig.brandColor,
          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppConfig.brandColor.withAlpha(30),
        ),
      ),
      home: const HomeShell(),
    );
  }
}

/// Donji meni: Početna, Pretraga, Sačuvano.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          SearchScreen(),
          SavedScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Početna',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Pretraga',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Sačuvano',
          ),
        ],
      ),
    );
  }
}
