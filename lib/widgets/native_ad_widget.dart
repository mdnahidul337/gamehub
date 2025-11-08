import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdWidget extends StatefulWidget {
  final NativeAd ad;

  const NativeAdWidget({super.key, required this.ad});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    // The listener is now set in the screen where the ad is created.
    // This widget is only responsible for loading and displaying the ad.
    if (widget.ad.responseInfo != null) {
      _isAdLoaded = true;
    } else {
      widget.ad.load();
    }
  }

  @override
  void dispose() {
    widget.ad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded) {
      return Container(
        height: 320,
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: AdWidget(ad: widget.ad),
      );
    } else {
      return const SizedBox(height: 320);
    }
  }
}
