import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../data/models/sponsored_content.dart';
import 'banner_ad_tile.dart';

/// Auto-rotating banner carousel inspired by Amazon home banners
/// - Uses PageView with a timer to auto-advance
/// - Accepts a list of SponsoredContent and tap handler generator
class RotatingBannerCarousel extends StatefulWidget {
  final List<SponsoredContent> items;
  final void Function(SponsoredContent ad)? onTap;
  final double height;
  final Duration interval;

  const RotatingBannerCarousel({
    super.key,
    required this.items,
    this.onTap,
    this.height = 140,
    this.interval = const Duration(seconds: 4),
  });

  @override
  State<RotatingBannerCarousel> createState() => _RotatingBannerCarouselState();
}

class _RotatingBannerCarouselState extends State<RotatingBannerCarousel> {
  final PageController _pageController = PageController(viewportFraction: 1);
  Timer? _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    if (widget.items.length > 1) {
      _timer = Timer.periodic(widget.interval, (_) {
        if (!mounted) return;
        _current = (_current + 1) % widget.items.length;
        _pageController.animateToPage(
          _current,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              final ad = widget.items[index];
              return BannerAdTile(
                ad: ad,
                onTap: widget.onTap != null ? () => widget.onTap!(ad) : null,
              );
            },
          ),
          // Simple dots indicator
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.items.length, (i) {
                final active = i == _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? Colors.black54 : Colors.black26,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
