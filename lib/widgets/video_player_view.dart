import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Plays a video from either a local file (while picking a new cover) or a
/// network URL (an already-uploaded cover), with a tap-to-play/pause overlay.
class VideoPlayerView extends StatefulWidget {
  final String? filePath;
  final String? networkUrl;

  const VideoPlayerView({super.key, this.filePath, this.networkUrl})
    : assert(
        (filePath != null) != (networkUrl != null),
        'Provide exactly one of filePath or networkUrl',
      );

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.filePath != null
        ? VideoPlayerController.file(File(widget.filePath!))
        : VideoPlayerController.networkUrl(Uri.parse(widget.networkUrl!));
    _controller
        .initialize()
        .then((_) {
          if (mounted) setState(() => _initialized = true);
        })
        .catchError((_) {
          if (mounted) setState(() => _failed = true);
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const Icon(Icons.error_outline),
      );
    }
    if (!_initialized) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
          if (!_controller.value.isPlaying)
            Container(
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
            ),
        ],
      ),
    );
  }
}
