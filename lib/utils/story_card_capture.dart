import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../config/api_config.dart';
import '../models/event.dart';
import '../widgets/event_story_card.dart';

/// Renders [EventStoryCard] off-screen (so nothing flashes on the real
/// screen) and exports it as a PNG file ready to hand to the share sheet.
/// Returns null if it couldn't be captured (e.g. the cover image failed to
/// load) - callers should fall back to a plain error message.
Future<File?> captureEventStoryCard({
  required BuildContext context,
  required Event event,
}) async {
  final coverUrl = event.coverImageUrl;
  if (coverUrl != null) {
    try {
      await precacheImage(NetworkImage(ApiConfig.mediaUrl(coverUrl)), context);
    } catch (_) {
      // Falls back to the plain gradient background baked into the card.
    }
  }
  if (!context.mounted) return null;

  final repaintKey = GlobalKey();
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -4000,
      top: 0,
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(
          key: repaintKey,
          child: EventStoryCard(event: event),
        ),
      ),
    ),
  );
  overlay.insert(entry);

  try {
    // Let the off-screen tree lay out and paint (the cover image is already
    // cached by now, but still needs a frame to actually show up).
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 50));
    await WidgetsBinding.instance.endOfFrame;

    final boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final dir = await Directory.systemTemp.createTemp('atryum_story');
    final file = File('${dir.path}/event_story.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  } finally {
    entry.remove();
  }
}
