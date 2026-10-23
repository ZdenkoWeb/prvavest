import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../post_list.dart';
import '../widgets.dart';

/// Početni ekran: kartice sa kategorijama i lista vesti.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Category>> _categories;

  @override
  void initState() {
    super.initState();
    _categories = WordPressApi.instance.fetchCategories();
  }

  void _retry() {
    setState(() => _categories = WordPressApi.instance.fetchCategories());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Category>>(
      future: _categories,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const PrvaVestLogo(), centerTitle: false),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        // Ako kategorije ne uspeju da se učitaju,
        // i dalje prikazujemo najnovije vesti.
        final cats = snap.data ?? const <Category>[];

        return DefaultTabController(
          key: ValueKey(cats.length),
          length: cats.length + 1,
          child: Scaffold(
            appBar: AppBar(
              title: const PrvaVestLogo(),
              centerTitle: false,
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  const Tab(text: 'Najnovije'),
                  for (final c in cats) Tab(text: c.name),
                ],
              ),
              actions: [
                if (snap.hasError)
                  IconButton(
                    tooltip: 'Učitaj kategorije',
                    icon: const Icon(Icons.refresh),
                    onPressed: _retry,
                  ),
              ],
            ),
            body: TabBarView(
              children: [
                const PostListView(),
                for (final c in cats)
                  PostListView(key: ValueKey(c.id), categoryId: c.id),
              ],
            ),
          ),
        );
      },
    );
  }
}
