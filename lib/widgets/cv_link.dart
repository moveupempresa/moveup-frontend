import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';

/// A tappable "Ver CV" link. Handles both an uploaded file (a relative
/// '/uploads/...' path) and a pasted external URL.
class CvLink extends StatelessWidget {
  final String cvUrl;

  const CvLink({super.key, required this.cvUrl});

  Future<void> _open(BuildContext context) async {
    final resolved = cvUrl.startsWith('http')
        ? cvUrl
        : ApiConfig.mediaUrl(cvUrl);
    final launched = await launchUrl(
      Uri.parse(resolved),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudo abrir el CV')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _open(context),
      icon: const Icon(Icons.description_outlined, size: 18),
      label: const Text('Ver CV'),
    );
  }
}
