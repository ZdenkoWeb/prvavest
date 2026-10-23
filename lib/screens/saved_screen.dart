import 'package:flutter/material.dart';

import '../saved_store.dart';
import '../theme.dart';
import '../widgets.dart';

/// Vesti koje je čitalac sačuvao za kasnije.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SavedStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final posts = store.posts;
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SectionTitle('Moje sačuvano'),
            if (posts.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
                child: Column(
                  children: [
                    Icon(Icons.bookmark_border, size: 44, color: context.muted),
                    const SizedBox(height: 12),
                    Text(
                      'Još nemaš sačuvanih vesti.\n'
                      'Dodirni ikonicu za čuvanje pored bilo koje vesti.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.muted, height: 1.5),
                    ),
                  ],
                ),
              ),
            for (var i = 0; i < posts.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: RowPost(post: posts[i]),
              ),
              if (i < posts.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 18,
                  endIndent: 18,
                  color: context.line,
                ),
            ],
          ],
        );
      },
    );
  }
}
