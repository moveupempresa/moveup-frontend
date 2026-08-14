import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile profile;
  final String token;

  const EditProfileScreen({
    super.key,
    required this.profile,
    required this.token,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late Profile _profile;
  late TextEditingController _displayNameController;
  late TextEditingController _artisticNameController;
  late TextEditingController _bioController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  late TextEditingController _websiteController;
  late TextEditingController _cvUrlController;
  late TextEditingController _experienceController;
  late TextEditingController _instagramController;
  late TextEditingController _tiktokController;
  late TextEditingController _youtubeController;
  late TextEditingController _facebookController;
  late TextEditingController _twitterController;

  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _isUploadingGalleryImage = false;
  bool _isUploadingCv = false;
  String? _removingGalleryId;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _displayNameController = TextEditingController(text: _profile.displayName);
    _artisticNameController = TextEditingController(
      text: _profile.artisticName,
    );
    _bioController = TextEditingController(text: _profile.bio);
    _cityController = TextEditingController(text: _profile.city);
    _countryController = TextEditingController(text: _profile.country);
    _websiteController = TextEditingController(text: _profile.websiteUrl);
    _cvUrlController = TextEditingController(text: _profile.cvUrl);
    _experienceController = TextEditingController(
      text: _profile.experience > 0 ? _profile.experience.toString() : '',
    );
    _instagramController = TextEditingController(
      text: _profile.socialLinks.instagram,
    );
    _tiktokController = TextEditingController(
      text: _profile.socialLinks.tiktok,
    );
    _youtubeController = TextEditingController(
      text: _profile.socialLinks.youtube,
    );
    _facebookController = TextEditingController(
      text: _profile.socialLinks.facebook,
    );
    _twitterController = TextEditingController(
      text: _profile.socialLinks.twitter,
    );
  }

  @override
  void dispose() {
    for (final c in [
      _displayNameController,
      _artisticNameController,
      _bioController,
      _cityController,
      _countryController,
      _websiteController,
      _cvUrlController,
      _experienceController,
      _instagramController,
      _tiktokController,
      _youtubeController,
      _facebookController,
      _twitterController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addGalleryMedia() async {
    final picked = await showModalBottomSheet<List<XFile>>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Añadir fotos'),
              onTap: () async {
                final files = await _picker.pickMultiImage(imageQuality: 85);
                if (ctx.mounted) Navigator.pop(ctx, files);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Añadir video'),
              onTap: () async {
                final f = await _picker.pickVideo(source: ImageSource.gallery);
                if (ctx.mounted) {
                  Navigator.pop(ctx, f != null ? [f] : <XFile>[]);
                }
              },
            ),
          ],
        ),
      ),
    );
    if (picked == null || picked.isEmpty) return;

    setState(() => _isUploadingGalleryImage = true);
    try {
      final updated = await ProfileService.addGalleryAlbum(
        token: widget.token,
        mediaFiles: picked.map((f) => File(f.path)).toList(),
      );
      if (mounted) setState(() => _profile = updated);
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isUploadingGalleryImage = false);
    }
  }

  Future<void> _removeGalleryAlbum(String id) async {
    setState(() => _removingGalleryId = id);
    try {
      final updated = await ProfileService.removeGalleryAlbum(
        token: widget.token,
        id: id,
      );
      setState(() => _profile = updated);
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _removingGalleryId = null);
    }
  }

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final updated = await ProfileService.uploadProfileImage(
        token: widget.token,
        imageFile: File(picked.path),
      );
      setState(() => _profile = updated);
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _pickAndUploadCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => _isUploadingCv = true);
    try {
      final updated = await ProfileService.uploadCv(
        token: widget.token,
        file: File(path),
      );
      if (mounted) {
        setState(() {
          _profile = updated;
          _cvUrlController.text = updated.cvUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CV subido correctamente')),
        );
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isUploadingCv = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final experienceText = _experienceController.text.trim();
      final updated = await ProfileService.updateProfile(
        token: widget.token,
        displayName: _displayNameController.text.trim(),
        artisticName: _artisticNameController.text.trim(),
        bio: _bioController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        websiteUrl: _websiteController.text.trim(),
        cvUrl: _cvUrlController.text.trim(),
        experience: experienceText.isEmpty ? 0 : int.parse(experienceText),
        socialLinks: {
          'instagram': _instagramController.text.trim(),
          'tiktok': _tiktokController.text.trim(),
          'youtube': _youtubeController.text.trim(),
          'facebook': _facebookController.text.trim(),
          'twitter': _twitterController.text.trim(),
        },
      );
      setState(() => _profile = updated);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _close() => Navigator.of(context).pop(_profile);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar perfil'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _close,
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Profile image
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: _profile.profileImage != null
                            ? NetworkImage(
                                ApiConfig.mediaUrl(_profile.profileImage!),
                              )
                            : null,
                        child: _isUploadingImage
                            ? const CircularProgressIndicator()
                            : _profile.profileImage == null
                            ? Text(
                                _profile.displayName.isNotEmpty
                                    ? _profile.displayName[0].toUpperCase()
                                    : '?',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton.filled(
                          icon: const Icon(Icons.camera_alt, size: 18),
                          onPressed: _isUploadingImage
                              ? null
                              : _pickProfileImage,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _sectionHeader('Información básica'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de visualización',
                  ),
                  validator: (v) => v != null && v.trim().length > 100
                      ? 'Máx. 100 caracteres'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _artisticNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre artístico',
                  ),
                  validator: (v) => v != null && v.trim().length > 100
                      ? 'Máx. 100 caracteres'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioController,
                  maxLength: 500,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Biografía',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _experienceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Años de experiencia',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 0 || n > 100) {
                      return 'Ingresa un número entre 0 y 100';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                _sectionHeader('Ubicación'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'Ciudad'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(labelText: 'País'),
                ),
                const SizedBox(height: 24),

                _sectionHeader('Enlaces'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(labelText: 'Sitio web'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cvUrlController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'URL del CV',
                    suffixIcon: IconButton(
                      icon: _isUploadingCv
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file_outlined),
                      tooltip: 'Subir CV (PDF o imagen)',
                      onPressed: _isUploadingCv ? null : _pickAndUploadCv,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _sectionHeader('Redes sociales'),
                const SizedBox(height: 12),
                _socialField(
                  _instagramController,
                  'Instagram',
                  Icons.camera_alt_outlined,
                ),
                const SizedBox(height: 12),
                _socialField(
                  _tiktokController,
                  'TikTok',
                  Icons.music_note_outlined,
                ),
                const SizedBox(height: 12),
                _socialField(
                  _youtubeController,
                  'YouTube',
                  Icons.play_circle_outline,
                ),
                const SizedBox(height: 12),
                _socialField(
                  _facebookController,
                  'Facebook',
                  Icons.facebook_outlined,
                ),
                const SizedBox(height: 12),
                _socialField(
                  _twitterController,
                  'Twitter / X',
                  Icons.alternate_email,
                ),
                const SizedBox(height: 32),

                _sectionHeader('Galería'),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _profile.gallery.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _profile.gallery.length) {
                      return InkWell(
                        onTap: _isUploadingGalleryImage
                            ? null
                            : _addGalleryMedia,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: _isUploadingGalleryImage
                              ? const CircularProgressIndicator()
                              : const Icon(Icons.add_photo_alternate_outlined),
                        ),
                      );
                    }
                    final album = _profile.gallery[index];
                    final isVideo = album.isVideo;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: isVideo
                              ? Container(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    size: 32,
                                  ),
                                )
                              : Image.network(
                                  ApiConfig.mediaUrl(album.urls.first),
                                  fit: BoxFit.cover,
                                ),
                        ),
                        if (album.urls.length > 1)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.photo_library,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${album.urls.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_removingGalleryId == album.id)
                          const Positioned.fill(
                            child: ColoredBox(
                              color: Colors.black45,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          )
                        else
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeGalleryAlbum(album.id),
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleSmall);
  }

  Widget _socialField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}
