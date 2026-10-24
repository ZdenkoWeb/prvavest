import 'package:flutter/material.dart';

import '../api.dart';
import '../config.dart';
import '../header.dart';
import '../models.dart';
import '../nav.dart';
import '../post_list.dart';
import '../theme.dart';
import '../widgets.dart';

/// Spisak svih rubrika, a ispod crno podnožje kao na sajtu.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<Category>> _future = WordPressApi.instance.categories();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Category>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return ErrorRetry(
            message: 'Rubrike trenutno ne mogu da se učitaju. '
                'Proveri internet vezu.',
            onRetry: () => setState(() {
              _future = WordPressApi.instance.categories(refresh: true);
            }),
          );
        }
        final cats = snap.data ?? const <Category>[];
        return ListView(
          children: [
            const SectionTitle('Kategorije'),
            for (final c in cats) ...[
              InkWell(
                onTap: () => openCategory(context, c),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.slug == AppConfig.highlightedSlug
                              ? chipLabel(c)
                              : c.name,
                          style: TextStyle(
                            fontFamily: kSerif,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: c.slug == AppConfig.highlightedSlug
                                ? AppConfig.brandTextColor
                                : context.ink,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: context.muted),
                    ],
                  ),
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                indent: 18,
                endIndent: 18,
                color: context.line,
              ),
            ],
            const SizedBox(height: 28),
            const SiteFooter(),
          ],
        );
      },
    );
  }
}

/// Vesti iz jedne rubrike (otvara se iz trake, menija ili Kategorija).
class CategoryScreen extends StatelessWidget {
  final Category category;
  const CategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomMenu(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SiteHeader(
              onBack: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CategoryLabel(category.name, size: 15),
              ),
            ),
            Expanded(
              child: PostListView(
                key: ValueKey(category.id),
                categoryId: category.id,
                style: PostListStyle.home,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
