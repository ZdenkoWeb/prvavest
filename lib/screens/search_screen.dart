import 'package:flutter/material.dart';

import '../post_list.dart';
import '../theme.dart';

/// Pretraga vesti po reči (npr. "Đoković", "izbori").
/// Otvara se lupom u zaglavlju ili dodirom na oznaku ispod vesti.
class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  late String _query = widget.initialQuery?.trim() ?? '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    setState(() => _query = value.trim());
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 14, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Nazad',
                    icon: Icon(Icons.arrow_back, color: context.ink),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: _query.isEmpty,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _submit,
                      style: TextStyle(color: context.ink, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Pretraži vesti…',
                        hintStyle: TextStyle(color: context.muted),
                        prefixIcon: Icon(Icons.search, color: context.muted),
                        suffixIcon: IconButton(
                          tooltip: 'Obriši',
                          icon: Icon(Icons.close, color: context.muted),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        ),
                        filled: true,
                        fillColor: context.box,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 4, color: context.box),
            Expanded(
              child: _query.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Ukucaj pojam i pritisni pretragu na tastaturi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.muted),
                        ),
                      ),
                    )
                  : PostListView(
                      key: ValueKey(_query),
                      search: _query,
                      style: PostListStyle.plain,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
