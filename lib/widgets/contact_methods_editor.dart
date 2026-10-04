import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/user_service.dart';

const _socialPlatforms = [
  'instagram',
  'tiktok',
  'youtube',
  'facebook',
  'twitter',
];

String _socialPlatformLabel(String platform) => switch (platform) {
  'instagram' => 'Instagram',
  'tiktok' => 'TikTok',
  'youtube' => 'YouTube',
  'facebook' => 'Facebook',
  'twitter' => 'Twitter / X',
  _ => platform,
};

String _socialLinkValue(SocialLinks links, String platform) =>
    switch (platform) {
      'instagram' => links.instagram,
      'tiktok' => links.tiktok,
      'youtube' => links.youtube,
      'facebook' => links.facebook,
      'twitter' => links.twitter,
      _ => '',
    };

/// Lets the user choose 1-3 contact methods (Teléfono / Email / Red social)
/// from among their already-filled-in fields, entering a value right here
/// if one of those fields isn't set yet. Used both as a one-time, mandatory
/// step after signup and as an editable Ajustes screen.
class ContactMethodsEditor extends StatefulWidget {
  final String token;
  final User user;
  final Profile profile;
  final String saveLabel;
  final void Function(User user, Profile profile) onSaved;

  const ContactMethodsEditor({
    super.key,
    required this.token,
    required this.user,
    required this.profile,
    required this.onSaved,
    this.saveLabel = 'Guardar',
  });

  @override
  State<ContactMethodsEditor> createState() => _ContactMethodsEditorState();
}

class _ContactMethodsEditorState extends State<ContactMethodsEditor> {
  late bool _phoneEnabled;
  late bool _emailEnabled;
  late bool _socialEnabled;
  late String? _socialPlatform;
  late final TextEditingController _phoneController;
  late final TextEditingController _socialController;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final cm = widget.profile.contactMethods;
    _phoneEnabled = cm.phone;
    _emailEnabled = cm.email;
    _socialEnabled = cm.socialEnabled;
    _socialPlatform = cm.socialPlatform ?? _socialPlatforms.first;
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _socialController = TextEditingController(
      text: cm.socialPlatform != null
          ? _socialLinkValue(widget.profile.socialLinks, cm.socialPlatform!)
          : '',
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _socialController.dispose();
    super.dispose();
  }

  void _onSocialPlatformChanged(String? platform) {
    if (platform == null) return;
    setState(() {
      _socialPlatform = platform;
      _socialController.text = _socialLinkValue(
        widget.profile.socialLinks,
        platform,
      );
    });
  }

  Future<void> _save() async {
    setState(() => _error = null);

    if (!_phoneEnabled && !_emailEnabled && !_socialEnabled) {
      setState(() => _error = 'Selecciona al menos un método de contacto');
      return;
    }
    if (_phoneEnabled && _phoneController.text.trim().isEmpty) {
      setState(() => _error = 'Introduce un número de teléfono');
      return;
    }
    if (_socialEnabled &&
        (_socialPlatform == null || _socialController.text.trim().isEmpty)) {
      setState(
        () => _error = 'Introduce el usuario o enlace de esa red social',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      var user = widget.user;
      final newPhone = _phoneController.text.trim();
      if (_phoneEnabled && newPhone != (widget.user.phone ?? '')) {
        user = await UserService.changePhone(
          token: widget.token,
          phone: newPhone,
        );
      }

      final socialLinksUpdate = <String, String>{};
      if (_socialEnabled && _socialPlatform != null) {
        final newValue = _socialController.text.trim();
        if (newValue !=
            _socialLinkValue(widget.profile.socialLinks, _socialPlatform!)) {
          socialLinksUpdate[_socialPlatform!] = newValue;
        }
      }

      final profile = await ProfileService.updateProfile(
        token: widget.token,
        socialLinks: socialLinksUpdate.isNotEmpty ? socialLinksUpdate : null,
        contactMethods: ContactMethods(
          phone: _phoneEnabled,
          email: _emailEnabled,
          socialEnabled: _socialEnabled,
          socialPlatform: _socialEnabled ? _socialPlatform : null,
        ),
      );

      widget.onSaved(user, profile);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Teléfono'),
          value: _phoneEnabled,
          onChanged: (v) => setState(() => _phoneEnabled = v ?? false),
        ),
        if (_phoneEnabled)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                hintText: '+34 600 000 000',
              ),
            ),
          ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Email'),
          subtitle: Text(widget.user.email),
          value: _emailEnabled,
          onChanged: (v) => setState(() => _emailEnabled = v ?? false),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Red social'),
          value: _socialEnabled,
          onChanged: (v) => setState(() => _socialEnabled = v ?? false),
        ),
        if (_socialEnabled) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: DropdownButtonFormField<String>(
              value: _socialPlatform,
              decoration: const InputDecoration(labelText: 'Plataforma'),
              items: _socialPlatforms
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(_socialPlatformLabel(p)),
                    ),
                  )
                  .toList(),
              onChanged: _onSocialPlatformChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: TextField(
              controller: _socialController,
              decoration: InputDecoration(
                labelText: _socialPlatform != null
                    ? 'Usuario o enlace de ${_socialPlatformLabel(_socialPlatform!)}'
                    : 'Usuario o enlace',
              ),
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(_error!, style: TextStyle(color: colorScheme.error)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.saveLabel),
        ),
      ],
    );
  }
}
