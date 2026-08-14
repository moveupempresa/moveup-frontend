import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/profile.dart';

/// A row of icon buttons for whichever social links are set on the profile.
/// Each field may hold a full URL or just a handle/username - handles get
/// resolved against the platform's profile URL.
class SocialLinksRow extends StatelessWidget {
  final SocialLinks socialLinks;

  const SocialLinksRow({super.key, required this.socialLinks});

  static String _resolve(String value, String baseUrl) =>
      value.startsWith('http') ? value : '$baseUrl$value';

  Future<void> _open(BuildContext context, String url) async {
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = <(IconData, String, String)>[
      if (socialLinks.instagram.isNotEmpty)
        (
          Icons.camera_alt_outlined,
          'Instagram',
          _resolve(socialLinks.instagram, 'https://instagram.com/'),
        ),
      if (socialLinks.tiktok.isNotEmpty)
        (
          Icons.music_note_outlined,
          'TikTok',
          _resolve(socialLinks.tiktok, 'https://tiktok.com/@'),
        ),
      if (socialLinks.youtube.isNotEmpty)
        (
          Icons.play_circle_outline,
          'YouTube',
          _resolve(socialLinks.youtube, 'https://youtube.com/@'),
        ),
      if (socialLinks.facebook.isNotEmpty)
        (
          Icons.facebook_outlined,
          'Facebook',
          _resolve(socialLinks.facebook, 'https://facebook.com/'),
        ),
      if (socialLinks.twitter.isNotEmpty)
        (
          Icons.alternate_email,
          'Twitter / X',
          _resolve(socialLinks.twitter, 'https://x.com/'),
        ),
    ];
    if (entries.isEmpty) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.center,
      children: entries
          .map(
            (e) => IconButton(
              icon: Icon(e.$1),
              tooltip: e.$2,
              onPressed: () => _open(context, e.$3),
            ),
          )
          .toList(),
    );
  }
}
