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
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: profile.profileImage != null
                    ? NetworkImage(ApiConfig.mediaUrl(profile.profileImage!))
                    : null,
                child: profile.profileImage == null
                    ? Text(
                        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                        style: Theme.of(context).textTheme.titleMedium,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        location,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      profile.followersCount == 1
                          ? '1 seguidor'
                          : '${profile.followersCount} seguidores',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_outlined, color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
