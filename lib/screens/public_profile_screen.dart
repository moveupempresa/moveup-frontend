import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/event.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/profile_service.dart';
import '../services/user_service.dart';
import '../widgets/event_card.dart';
import '../widgets/image_viewer_dialog.dart';
import 'event_detail_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String token;
  final String userId;
  final String currentUserId;

  const PublicProfileScreen({
    super.key,
    required this.token,
    required this.userId,
    required this.currentUserId,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Profile? _profile;
  String? _username;
  List<Event>? _events;
  bool _loading = true;
  String? _error;

  bool _isFollowing = false;
  int _followersCount = 0;
  bool _isTogglingFollow = false;

  bool get _isOwnProfile => widget.userId == widget.currentUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ProfileService.getUserProfile(token: widget.token, userId: widget.userId),
        EventService.getPublicEvents(token: widget.token, userId: widget.userId),
      ]);
      final profileResult = results[0] as (Profile, String, bool, int);
      final events = results[1] as List<Event>;
      if (mounted) {
        setState(() {
          _profile = profileResult.$1;
          _username = profileResult.$2;
          _isFollowing = profileResult.$3;
          _followersCount = profileResult.$4;
          _events = events;
        });
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo cargar el perfil');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _isTogglingFollow = true);
    try {
      final (isFollowing, followersCount) = _isFollowing
          ? await UserService.unfollowUser(token: widget.token, userId: widget.userId)
          : await UserService.followUser(token: widget.token, userId: widget.userId);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
          _followersCount = followersCount;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isTogglingFollow = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_username ?? 'Perfil')),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(child: TextButton(onPressed: _load, child: const Text('Reintentar'))),
        ],
      );
    }

    final profile = _profile!;
    final name = profile.displayName.isNotEmpty ? profile.displayName : _username!;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundImage: profile.profileImage != null
                ? NetworkImage(ApiConfig.mediaUrl(profile.profileImage!))
                : null,
            child: profile.profileImage == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: Theme.of(context).textTheme.headlineMedium,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(name, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          _followersCount == 1 ? '1 seguidor' : '$_followersCount seguidores',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
          textAlign: TextAlign.center,
        ),
        if (!_isOwnProfile) ...[
          const SizedBox(height: 12),
          Center(
            child: _isFollowing
                ? OutlinedButton.icon(
                    onPressed: _isTogglingFollow ? null : _toggleFollow,
                    icon: _isTogglingFollow
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Siguiendo'),
                  )
                : FilledButton.icon(
                    onPressed: _isTogglingFollow ? null : _toggleFollow,
                    icon: _isTogglingFollow
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Seguir'),
                  ),
          ),
        ],
        if (profile.artisticName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            profile.artisticName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.primary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
        if (profile.city.isNotEmpty || profile.country.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            [profile.city, profile.country].where((s) => s.isNotEmpty).join(', '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
        if (profile.experience > 0) ...[
          const SizedBox(height: 4),
          Text(
            '${profile.experience} ${profile.experience == 1 ? 'año' : 'años'} de experiencia',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            profile.bio,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 32),
        Text('Galería', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: -24),
          child: profile.gallery.isEmpty
              ? Container(
                  height: 96,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Sin imágenes todavía'),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: profile.gallery.length,
                  itemBuilder: (context, index) {
                    final url = profile.gallery[index];
                    final isVideo = isGalleryVideoUrl(url);
                    return GestureDetector(
                      onTap: isVideo
                          ? null
                          : () => showImageViewer(context, ApiConfig.mediaUrl(url)),
                      child: isVideo
                          ? Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.play_circle_outline,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                size: 32,
                              ),
                            )
                          : Image.network(
                              ApiConfig.mediaUrl(url),
                              fit: BoxFit.cover,
                            ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 32),
        Text('Eventos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (_events == null || _events!.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text('Todavía no tiene eventos publicados'),
          )
        else
          Column(
            children: _events!
                .map((e) => EventCard(
                      event: e,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EventDetailScreen(
                            token: widget.token,
                            event: e,
                            currentUserId: widget.currentUserId,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }
}
