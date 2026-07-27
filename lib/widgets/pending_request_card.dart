import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/pending_request.dart';

class PendingRequestCard extends StatelessWidget {
  final PendingRequest request;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const PendingRequestCard({
    super.key,
    required this.request,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Image.network(
                  ApiConfig.mediaUrl(request.eventCoverMediaUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: request.profileImage != null
                            ? NetworkImage(ApiConfig.mediaUrl(request.profileImage!))
                            : null,
                        child: request.profileImage == null
                            ? Text(
                                request.requesterName.isNotEmpty
                                    ? request.requesterName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 11),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          request.requesterName,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${request.eventTitle} · ${request.packName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isProcessing)
              const Padding(
                padding: EdgeInsets.all(10),
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    color: Colors.green.shade700,
                    tooltip: 'Aprobar',
                    onPressed: onApprove,
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined),
                    color: Colors.red.shade700,
                    tooltip: 'Rechazar',
                    onPressed: onReject,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
