import 'package:flutter/material.dart';

import '../post_list.dart';

/// Naslovna: glavna vest velika, ispod ostale najnovije vesti.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PostListView(style: PostListStyle.home);
  }
}

/// Najnovije: sve vesti redom, sa brojevima kao na sajtu.
class LatestScreen extends StatelessWidget {
  const LatestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PostListView(style: PostListStyle.numbered);
  }
}
