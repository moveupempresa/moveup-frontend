import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/event.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/profile_service.dart';
import '../widgets/event_card.dart';
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
      final profileResult = results[0] as (Profile, String);
      final events = results[1] as List<Event>;
      if (mounted) {
        setState(() {
          _profile = profileResult.$1;
          _username = profileResult.$2;
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
        profile.gallery.isEmpty
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
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: profile.gallery.length,
                itemBuilder: (context, index) {
                  final url = profile.gallery[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isGalleryVideoUrl(url)
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
