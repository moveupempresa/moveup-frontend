import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/event.dart';
import '../models/profile.dart';
import '../models/user.dart';
import '../services/event_service.dart';
import '../services/notification_service.dart';
import '../widgets/events_locked_banner.dart';
import '../widgets/image_viewer_dialog.dart';
import '../widgets/profile_events_section.dart';
import '../widgets/sliver_tab_bar_delegate.dart';
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
      final notifications = await NotificationService.getMyNotifications(
        token: widget.token,
      );
      if (mounted) {
        setState(
          () => _hasUnreadNotifications = notifications.any((n) => !n.read),
        );
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
        builder: (_) =>
            EditProfileScreen(profile: _profile, token: widget.token),
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
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(token: widget.token),
                ),
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
                  builder: (_) =>
                      SettingsScreen(token: widget.token, user: _user),
                ),
              );
              if (updatedUser != null) setState(() => _user = updatedUser);
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(child: _buildHeader(context, name)),
            SliverPersistentHeader(
              pinned: true,
              delegate: SliverTabBarDelegate(
                TabBar(
                  tabs: const [
                    Tab(text: 'Galería'),
                    Tab(text: 'Eventos'),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [_buildGaleriaTab(context), _buildEventosTab(context)],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
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
              [
                _profile.city,
                _profile.country,
              ].where((s) => s.isNotEmpty).join(', '),
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
              fontStyle: _profile.bio.isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _editProfile,
            child: const Text('Editar perfil'),
          ),
        ],
      ),
    );
  }

  Widget _buildGaleriaTab(BuildContext context) {
    if (_profile.gallery.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.photo_library_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'Sin imágenes todavía',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 0.75,
      ),
      itemCount: _profile.gallery.length,
      itemBuilder: (context, index) {
        final album = _profile.gallery[index];
        final isVideo = album.isVideo;
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: isVideo
                    ? null
                    : () => showImageViewer(
                        context,
                        album.urls.map(ApiConfig.mediaUrl).toList(),
                      ),
                child: isVideo
                    ? Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventosTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ProfileEventsSection(
          events: _events,
          isLoading: _loadingEvents,
          error: _eventsError,
          onRetry: _loadEvents,
          emptyMessage: 'Todavía no tienes eventos publicados',
          lockedBanner: _user.subscriptionPlan == SubscriptionPlan.free
              ? EventsLockedBanner(
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
              : null,
          onEventTap: (e) async {
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
        ),
      ],
    );
  }
}
