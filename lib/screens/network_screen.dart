import 'package:flutter/material.dart';

import '../models/popular_profile.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/following_profile_card.dart';
import 'public_profile_screen.dart';

enum NetworkMode { following, followers, favorites }

/// Seguidores / Seguidos / Favoritos, reached from the user's own profile -
/// previously a "Mi red" tab inside Mi espacio, now Instagram-style:
/// accessible from the profile itself.
class NetworkScreen extends StatefulWidget {
  final String token;
  final String currentUserId;
  final NetworkMode initialMode;

  const NetworkScreen({
    super.key,
    required this.token,
    required this.currentUserId,
    this.initialMode = NetworkMode.following,
  });

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  late NetworkMode _mode = widget.initialMode;
  List<PopularProfile>? _following;
  bool _loadingFollowing = false;
  String? _followingError;
  List<PopularProfile>? _followers;
  bool _loadingFollowers = false;
  String? _followersError;
  List<PopularProfile>? _favorites;
  bool _loadingFavorites = false;
  String? _favoritesError;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
    _loadFollowers();
    _loadFavorites();
  }

  Future<void> _loadFollowing() async {
    setState(() {
      _loadingFollowing = true;
      _followingError = null;
    });
    try {
      final profiles = await UserService.getMyFollowing(token: widget.token);
      if (mounted) setState(() => _following = profiles);
    } catch (e) {
      if (mounted) setState(() => _followingError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingFollowing = false);
    }
  }

  Future<void> _loadFollowers() async {
    setState(() {
      _loadingFollowers = true;
      _followersError = null;
    });
    try {
      final profiles = await UserService.getMyFollowers(token: widget.token);
      if (mounted) setState(() => _followers = profiles);
    } catch (e) {
      if (mounted) setState(() => _followersError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingFollowers = false);
    }
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _loadingFavorites = true;
      _favoritesError = null;
    });
    try {
      final profiles = await UserService.getMyFavorites(token: widget.token);
      if (mounted) setState(() => _favorites = profiles);
    } catch (e) {
      if (mounted) setState(() => _favoritesError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingFavorites = false);
    }
  }

  Future<void> _toggleFavorite(PopularProfile profile) async {
    try {
      final isFavorite = profile.isFavorite
          ? await UserService.removeFavorite(
              token: widget.token,
              userId: profile.userId,
            )
          : await UserService.addFavorite(
              token: widget.token,
              userId: profile.userId,
            );
      if (!mounted) return;
      setState(() {
        _following = _following
            ?.map(
              (p) => p.userId == profile.userId
                  ? p.copyWith(isFavorite: isFavorite)
                  : p,
            )
            .toList();
        _followers = _followers
            ?.map(
              (p) => p.userId == profile.userId
                  ? p.copyWith(isFavorite: isFavorite)
                  : p,
            )
            .toList();
        if (isFavorite) {
          if (_favorites != null &&
              !_favorites!.any((p) => p.userId == profile.userId)) {
            _favorites = [profile.copyWith(isFavorite: true), ..._favorites!];
          }
        } else {
          _favorites = _favorites
              ?.where((p) => p.userId != profile.userId)
              .toList();
        }
      });
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi red')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<NetworkMode>(
              segments: [
                ButtonSegment(
                  value: NetworkMode.following,
                  label: Text(
                    _following != null
                        ? 'Siguiendo (${_following!.length})'
                        : 'Siguiendo',
                  ),
                ),
                ButtonSegment(
                  value: NetworkMode.followers,
                  label: Text(
                    _followers != null
                        ? 'Seguidores (${_followers!.length})'
                        : 'Seguidores',
                  ),
                ),
                ButtonSegment(
                  value: NetworkMode.favorites,
                  label: Text(
                    _favorites != null
                        ? 'Favoritos (${_favorites!.length})'
                        : 'Favoritos',
                  ),
                ),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _mode = selection.first),
            ),
          ),
          Expanded(
            child: switch (_mode) {
              NetworkMode.following => _buildProfileList(
                profiles: _following,
                isLoading: _loadingFollowing,
                error: _followingError,
                onRetry: _loadFollowing,
                emptyMessage: 'Todavía no sigues a ningún perfil',
              ),
              NetworkMode.followers => _buildProfileList(
                profiles: _followers,
                isLoading: _loadingFollowers,
                error: _followersError,
                onRetry: _loadFollowers,
                emptyMessage: 'Todavía no tienes seguidores',
              ),
              NetworkMode.favorites => _buildProfileList(
                profiles: _favorites,
                isLoading: _loadingFavorites,
                error: _favoritesError,
                onRetry: _loadFavorites,
                emptyMessage:
                    'Marca perfiles como favoritos ⭐ para descubrir rápido sus nuevos eventos',
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileList({
    required List<PopularProfile>? profiles,
    required bool isLoading,
    required String? error,
    required VoidCallback onRetry,
    required String emptyMessage,
  }) {
    if (isLoading && profiles == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && profiles == null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.error_outline,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          const Text(
            'No se pudo cargar la información',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }

    final results = profiles ?? [];
    if (results.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.people_outline,
            size: 40,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadFollowing();
        _loadFollowers();
        _loadFavorites();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final profile = results[index];
          return FollowingProfileCard(
            profile: profile,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PublicProfileScreen(
                  token: widget.token,
                  userId: profile.userId,
                  currentUserId: widget.currentUserId,
                ),
              ),
            ),
            onToggleFavorite: () => _toggleFavorite(profile),
          );
        },
      ),
    );
  }
}
