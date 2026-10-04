import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/contact_info.dart';
import '../models/profile.dart';
import '../models/user.dart';

IconData _socialIcon(String platform) => switch (platform) {
  'instagram' => Icons.camera_alt_outlined,
  'tiktok' => Icons.music_note_outlined,
  'youtube' => Icons.play_circle_outline,
  'facebook' => Icons.facebook_outlined,
  'twitter' => Icons.alternate_email,
  _ => Icons.link,
};

String _socialLabel(String platform) => switch (platform) {
  'instagram' => 'Instagram',
  'tiktok' => 'TikTok',
  'youtube' => 'YouTube',
  'facebook' => 'Facebook',
  'twitter' => 'Twitter / X',
  _ => platform,
};

String _socialUrl(String platform, String value) {
  if (value.startsWith('http')) return value;
  final base = switch (platform) {
    'instagram' => 'https://instagram.com/',
    'tiktok' => 'https://tiktok.com/@',
    'youtube' => 'https://youtube.com/@',
    'facebook' => 'https://facebook.com/',
    'twitter' => 'https://x.com/',
    _ => '',
  };
  return '$base$value';
}

/// Displays a user's chosen contact methods (Teléfono / Email / Red
/// social) as tappable chips - on a profile, or an event's "Contactar con
/// el creador" section.
class ContactMethodsRow extends StatelessWidget {
  final String? phone;
  final String? email;
  final String? socialPlatform;
  final String? socialValue;
  final WrapAlignment alignment;

  const ContactMethodsRow({
    super.key,
    this.phone,
    this.email,
    this.socialPlatform,
    this.socialValue,
    this.alignment = WrapAlignment.start,
  });

  factory ContactMethodsRow.fromContactInfo(
    ContactInfo? contact, {
    WrapAlignment alignment = WrapAlignment.start,
  }) => ContactMethodsRow(
    phone: contact?.phone,
    email: contact?.email,
    socialPlatform: contact?.socialPlatform,
    socialValue: contact?.socialValue,
    alignment: alignment,
  );

  /// For the signed-in user's own profile, where their [User]/[Profile] are
  /// already loaded - no need for the server to resolve the methods first.
  factory ContactMethodsRow.fromProfile({
    required User user,
    required Profile profile,
    WrapAlignment alignment = WrapAlignment.start,
  }) {
    final cm = profile.contactMethods;
    final platform = cm.socialEnabled ? cm.socialPlatform : null;
    return ContactMethodsRow(
      phone: cm.phone ? user.phone : null,
      email: cm.email ? user.email : null,
      socialPlatform: platform,
      socialValue: platform != null
          ? _socialLinkValueFor(profile, platform)
          : null,
      alignment: alignment,
    );
  }

  static String? _socialLinkValueFor(Profile profile, String platform) {
    final value = switch (platform) {
      'instagram' => profile.socialLinks.instagram,
      'tiktok' => profile.socialLinks.tiktok,
      'youtube' => profile.socialLinks.youtube,
      'facebook' => profile.socialLinks.facebook,
      'twitter' => profile.socialLinks.twitter,
      _ => '',
    };
    return value.isEmpty ? null : value;
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudo abrir')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (phone != null)
        ActionChip(
          avatar: const Icon(Icons.phone_outlined, size: 18),
          label: Text(phone!),
          onPressed: () => _open(context, Uri.parse('tel:$phone')),
        ),
      if (email != null)
        ActionChip(
          avatar: const Icon(Icons.email_outlined, size: 18),
          label: Text(email!),
          onPressed: () => _open(context, Uri.parse('mailto:$email')),
        ),
      if (socialValue != null && socialPlatform != null)
        ActionChip(
          avatar: Icon(_socialIcon(socialPlatform!), size: 18),
          label: Text(_socialLabel(socialPlatform!)),
          onPressed: () => _open(
            context,
            Uri.parse(_socialUrl(socialPlatform!, socialValue!)),
          ),
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      alignment: alignment,
      spacing: 8,
      runSpacing: 4,
      children: chips,
    );
  }
}
