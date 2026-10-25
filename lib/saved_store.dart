import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Čuva sačuvane vesti u memoriji telefona, tako da ostanu
/// i kad se aplikacija zatvori.
class SavedStore extends ChangeNotifier {
  SavedStore._();
  static final SavedStore instance = SavedStore._();

  static const _key = 'saved_posts';
  final List<Post> _posts = [];

  List<Post> get posts => List.unmodifiable(_posts);

  bool isSaved(int id) => _posts.any((p) => p.id == id);

  /// Da li je vest sa ovom adresom sačuvana (za naslovnu sa sajta).
  bool isSavedLink(String link) =>
      _posts.any((p) => _sameLink(p.link, link));

  static bool _sameLink(String a, String b) {
    String n(String x) => x.replaceAll(RegExp(r'/+$'), '').toLowerCase();
    return n(a) == n(b);
  }

  Future<void> removeLink(String link) async {
    for (final p in _posts) {
      if (_sameLink(p.link, link)) {
        await toggle(p);
        return;
      }
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _posts
        ..clear()
        ..addAll(list.map((m) => Post.fromMap(m as Map<String, dynamic>)));
      notifyListeners();
    } catch (_) {
      // Ako su podaci oštećeni, krećemo od prazne liste.
    }
  }

  Future<void> toggle(Post post) async {
    if (isSaved(post.id)) {
      _posts.removeWhere((p) => p.id == post.id);
    } else {
      _posts.insert(0, post);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_posts.map((p) => p.toMap()).toList()),
    );
  }
}
