import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../header.dart';
import '../nav.dart';
import '../theme.dart';
import '../widgets.dart';

void openContact(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ContactScreen()),
  );
}

/// Ekran "Kontakt": izdavač, e-mail, sajt i impresum.
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

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
              showChips: false,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const SectionTitle('Kontakt'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Text(
                      '${AppConfig.publisherName} – izdavač portala '
                      'prvavest.com i ove aplikacije. Za pitanja, '
                      'primedbe, ispravke i saradnju pišite nam.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: context.ink,
                      ),
                    ),
                  ),
                  _ContactTile(
                    icon: Icons.mail_outline,
                    label: 'E-mail',
                    value: AppConfig.contactEmail,
                    onTap: () => openLink(
                      context,
                      'mailto:${AppConfig.contactEmail}',
                    ),
                    onLongPress: () {
                      Clipboard.setData(
                        const ClipboardData(text: AppConfig.contactEmail),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('E-mail je kopiran.')),
                      );
                    },
                  ),
                  _ContactTile(
                    icon: Icons.edit_note,
                    label: 'Redakcija',
                    value: AppConfig.newsroomEmail,
                    onTap: () => openLink(
                      context,
                      'mailto:${AppConfig.newsroomEmail}',
                    ),
                  ),
                  _ContactTile(
                    icon: Icons.business_outlined,
                    label: 'Izdavač',
                    value: AppConfig.publisherCompany,
                  ),
                  _ContactTile(
                    icon: Icons.public,
                    label: 'Sajt',
                    value: 'prvavest.com',
                    onTap: () => openLink(context, AppConfig.siteUrl),
                  ),
                  _ContactTile(
                    icon: Icons.contact_page_outlined,
                    label: 'Kontakt stranica',
                    value: 'prvavest.com/kontakt',
                    onTap: () => openLink(context, AppConfig.contactPageUrl),
                  ),
                  _ContactTile(
                    icon: Icons.info_outline,
                    label: 'Impresum',
                    value: 'prvavest.com/impresum',
                    onTap: () => openLink(context, AppConfig.impressumUrl),
                  ),
                  _ContactTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Politika privatnosti',
                    value: 'prvavest.com/politika-privatnosti',
                    onTap: () => openLink(context, AppConfig.privacyUrl),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, color: AppConfig.brandColor),
      title: Text(
        label,
        style: TextStyle(fontSize: 13.5, color: context.muted),
      ),
      subtitle: SelectableText(
        value,
        onTap: onTap,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: context.ink,
        ),
      ),
      trailing: onTap == null
          ? null
          : Icon(Icons.chevron_right, color: context.muted),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
