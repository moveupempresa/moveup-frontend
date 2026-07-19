import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/popular_profile.dart';

/// Compact avatar card for the "Perfiles populares" horizontal row.
class ProfileMiniCard extends StatelessWidget {
  final PopularProfile profile;
  final VoidCallback onTap;

  const ProfileMiniCard({super.key, required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
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
              const SizedBox(height: 6),
              Text(
                profile.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                profile.followersCount == 1
                    ? '1 seguidor'
                    : '${profile.followersCount} seguidores',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 11,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
