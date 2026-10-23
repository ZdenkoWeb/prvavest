import 'package:flutter/material.dart';

import '../saved_store.dart';
import '../widgets.dart';

/// Vesti koje je čitalac sačuvao za kasnije.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SavedStore.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Sačuvano')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final posts = store.posts;
          if (posts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Još nemaš sačuvanih vesti.\n'
                  'Otvori vest i dodirni ikonicu za čuvanje.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => PostTile(post: posts[i]),
          );
        },
      ),
    );
  }
}
