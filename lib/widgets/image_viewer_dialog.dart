import 'package:flutter/material.dart';

void showImageViewer(BuildContext context, List<String> imageUrls, {int initialIndex = 0}) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.7,
        width: double.infinity,
        child: _ImageCarousel(imageUrls: imageUrls, initialIndex: initialIndex),
      ),
    ),
  );
}

class _ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _ImageCarousel({required this.imageUrls, required this.initialIndex});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _page = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) => InteractiveViewer(
              child: Image.network(
                widget.imageUrls[index],
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (i) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page ? Colors.white : Colors.white38,
                  ),
                ),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          style: IconButton.styleFrom(backgroundColor: Colors.black45),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
