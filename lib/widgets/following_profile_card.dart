import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/popular_profile.dart';

class FollowingProfileCard extends StatelessWidget {
  final PopularProfile profile;
  final VoidCallback onTap;

  const FollowingProfileCard({super.key, required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final location = [profile.city, profile.country].where((s) => s.isNotEmpty).join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: profile.profileImage != null
                  ? Image.network(
                      ApiConfig.mediaUrl(profile.profileImage!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackAvatar(context),
                    )
                  : _fallbackAvatar(context),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.chevron_right_outlined, color: Theme.of(context).colorScheme.outline),
                    ],
                  ),
                  if (profile.artisticName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      profile.artisticName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (location.isNotEmpty) ...[
                    _infoRow(context, Icons.place_outlined, location),
                    const SizedBox(height: 4),
                  ],
                  if (profile.experience > 0) ...[
                    _infoRow(
                      context,
                      Icons.military_tech_outlined,
                      '${profile.experience} ${profile.experience == 1 ? 'año' : 'años'} de experiencia',
                    ),
                    const SizedBox(height: 4),
                  ],
                  _infoRow(
                    context,
                    Icons.people_outline,
                    profile.followersCount == 1
                        ? '1 seguidor'
                        : '${profile.followersCount} seguidores',
                  ),
                  if (profile.bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      profile.bio,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _fallbackAvatar(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(
        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
        style: Theme.of(context).textTheme.displayMedium,
      ),
    );
  }
}
