import 'package:flutter/material.dart';

import 'api.dart';
import 'config.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

/// Kako lista izgleda:
/// home     – prva vest velika, ostale sa slikom levo
/// numbered – vesti sa brojevima 1, 2, 3... (Najnovije)
/// plain    – sve sa slikom levo (pretraga)
enum PostListStyle { home, numbered, plain }

/// Lista vesti koja se sama dopunjava kad skroluješ do dna,
/// a osvežava se povlačenjem nadole.
class PostListView extends StatefulWidget {
  final int? categoryId;
  final String? search;
  final PostListStyle style;

  const PostListView({
    super.key,
    this.categoryId,
    this.search,
    this.style = PostListStyle.home,
  });

  @override
  State<PostListView> createState() => _PostListViewState();
}

class _PostListViewState extends State<PostListView>
    with AutomaticKeepAliveClientMixin {
  final _posts = <Post>[];
  final _scroll = ScrollController();
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) {
        _loadMore();
      }
    });
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final next = await WordPressApi.instance.fetchPosts(
        page: _page + 1,
        categoryId: widget.categoryId,
        search: widget.search,
      );
      if (!mounted) return;
      setState(() {
        _page++;
        // Preskačemo duplikate (ako je u međuvremenu izašla nova vest).
        final ids = _posts.map((p) => p.id).toSet();
        _posts.addAll(next.where((p) => !ids.contains(p.id)));
        _hasMore = next.length >= AppConfig.pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Vesti trenutno ne mogu da se učitaju. '
          'Proveri internet vezu.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _posts.clear();
      _page = 0;
      _hasMore = true;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_posts.isEmpty) {
      if (_error != null) {
        return ErrorRetry(message: _error!, onRetry: _refresh);
      }
      if (_loading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Nema vesti.', style: TextStyle(color: context.muted)),
        ),
      );
    }

    final showFooter = _loading || _error != null;
    return RefreshIndicator(
      color: AppConfig.brandColor,
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        itemCount: _posts.length + (showFooter ? 1 : 0),
        separatorBuilder: (_, _) => const _Line(),
        itemBuilder: (context, i) {
          if (i == _posts.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: _error != null
                    ? TextButton(
                        onPressed: _loadMore,
                        child: const Text('Učitaj još'),
                      )
                    : const CircularProgressIndicator(),
              ),
            );
          }
          final post = _posts[i];
          if (i == 0 && widget.style == PostListStyle.home) {
            return Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 6),
              child: HeroPost(post: post),
            );
          }
          return RowPost(
            post: post,
            number: widget.style == PostListStyle.numbered ? i + 1 : null,
          );
        },
      ),
    );
  }
}

/// Tanka linija između vesti (prati svetlu/tamnu temu).
class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: context.line);
}
