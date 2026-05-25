import 'package:flutter/material.dart';

import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import 'app_image.dart';

class BannerCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const BannerCarousel({super.key, required this.imageUrls});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    return Column(
      children: <Widget>[
        ClipRRect(
          borderRadius: AppRadius.largeAll,
          child: SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (int i) => setState(() => _index = i),
              itemCount: widget.imageUrls.length,
              itemBuilder: (BuildContext context, int i) {
                return AppImage(imagePath: widget.imageUrls[i]);
              },
            ),
          ),
        ),
        AppSpacing.vSm,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(widget.imageUrls.length, (int i) {
            final bool active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : const Color(0xFFD1D5DB),
                borderRadius: AppRadius.pillAll,
              ),
            );
          }),
        ),
      ],
    );
  }
}
