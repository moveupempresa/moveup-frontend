import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/event.dart';
import '../models/profile.dart';
import '../models/user.dart';
import '../services/event_service.dart';
import '../services/notification_service.dart';
import '../widgets/event_card.dart';
import '../widgets/image_viewer_dialog.dart';
import 'edit_profile_screen.dart';
import 'event_detail_screen.dart';
import 'settings/notifications_screen.dart';
import 'settings/pro_plan_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  final Profile profile;
  final String token;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.profile,
    required this.token,
  });

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  late Profile _profile;
  late User _user;
  List<Event>? _events;
  bool _loadingEvents = false;
  String? _eventsError;
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _user = widget.user;
    if (_user.subscriptionPlan == SubscriptionPlan.pro) {
      _loadEvents();
    }
    _loadNotificationStatus();
  }

  Future<void> _loadNotificationStatus() async {
    try {
      final notifications = await NotificationService.getMyNotifications(token: widget.token);
      if (mounted) {
        setState(() => _hasUnreadNotifications = notifications.any((n) => !n.read));
      }
    } catch (_) {
      // Keep the current badge state if this background check fails.
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loadingEvents = true;
      _eventsError = null;
    });
    try {
      final events = await EventService.getMyEvents(token: widget.token);
      if (mounted) setState(() => _events = events);
    } catch (e) {
      if (mounted) setState(() => _eventsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingEvents = false);
    }
  }

  void refreshEvents() {
    if (_user.subscriptionPlan == SubscriptionPlan.pro) _loadEvents();
  }

  Future<void> _editProfile() async {
    final updated = await Navigator.of(context).push<Profile>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(profile: _profile, token: widget.token),
      ),
    );
    if (updated != null) setState(() => _profile = updated);
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile.displayName.isNotEmpty
        ? _profile.displayName
        : _user.username;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _hasUnreadNotifications,
              smallSize: 8,
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Notificaciones',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => NotificationsScreen(token: widget.token)),
              );
              _loadNotificationStatus();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuración',
            onPressed: () async {
              final updatedUser = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    token: widget.token,
                    user: _user,
                  ),
                ),
              );
              if (updatedUser != null) setState(() => _user = updatedUser);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundImage: _profile.profileImage != null
                  ? NetworkImage(ApiConfig.mediaUrl(_profile.profileImage!))
                  : null,
              child: _profile.profileImage == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: Theme.of(context).textTheme.headlineMedium,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (_profile.artisticName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _profile.artisticName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          if (_profile.city.isNotEmpty || _profile.country.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              [_profile.city, _profile.country]
                  .where((s) => s.isNotEmpty)
                  .join(', '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          if (_profile.experience > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${_profile.experience} ${_profile.experience == 1 ? 'año' : 'años'} de experiencia',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            _profile.bio.isNotEmpty ? _profile.bio : 'Sin biografía',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle:
                      _profile.bio.isEmpty ? FontStyle.italic : FontStyle.normal,
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _editProfile,
            child: const Text('Editar perfil'),
          ),
          const SizedBox(height: 32),
          Text('Galería', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _profile.gallery.isEmpty
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
                    crossAxisCount: 2,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _profile.gallery.length,
                  itemBuilder: (context, index) {
                    final url = _profile.gallery[index];
                    final isVideo = isGalleryVideoUrl(url);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GestureDetector(
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
                      ),
                    );
                  },
                ),
          const SizedBox(height: 32),
          Text('Eventos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (_user.subscriptionPlan == SubscriptionPlan.free)
            _EventsLockedBanner(
              onUpgrade: () async {
                final updatedUser = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProPlanScreen(
                      token: widget.token,
                      subscriptionPlan: SubscriptionPlan.free,
                    ),
                  ),
                );
                if (updatedUser != null) {
                  setState(() => _user = updatedUser);
                  _loadEvents();
                }
              },
            )
          else if (_loadingEvents)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_eventsError != null)
            _ErrorBanner(onRetry: _loadEvents)
          else if (_events == null || _events!.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text('Todavía no tienes eventos publicados'),
            )
          else
            Column(
              children: _events!
                  .map((e) => EventCard(
                        event: e,
                        onTap: () async {
                          final changed = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => EventDetailScreen(
                                token: widget.token,
                                event: e,
                                currentUserId: _user.id,
                              ),
                            ),
                          );
                          if (changed == true) _loadEvents();
                        },
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('No se pudieron cargar los eventos'),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _EventsLockedBanner extends StatelessWidget {
  final VoidCallback onUpgrade;

  const _EventsLockedBanner({required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Los eventos son exclusivos del plan Pro',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onUpgrade,
            child: const Text('Ver plan Pro'),
          ),
        ],
      ),
    );
  }
}
