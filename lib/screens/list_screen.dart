import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../config/ad_config.dart';
import '../models/mod_item.dart';
import '../services/db_service.dart';
import '../widgets/mod_list.dart';

class ListScreen extends StatefulWidget {
  final String searchQuery;
  const ListScreen({super.key, this.searchQuery = ''});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  BannerAd? _bannerAd;
  final List<NativeAd> _nativeAds = [];
  final int _nativeAdFrequency = 2;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    for (var ad in _nativeAds) {
      ad.dispose();
    }
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {});
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void _loadNativeAd(int index) {
    if (index % _nativeAdFrequency == 0) {
      final ad = NativeAd(
        adUnitId: AdConfig.nativeAdUnitId,
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            setState(() {
              _nativeAds.add(ad as NativeAd);
            });
          },
          onAdFailedToLoad: (ad, err) {
            ad.dispose();
          },
        ),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
        ),
      )..load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DBService>(context, listen: false);
    return Scaffold(
      body: FutureBuilder<List<ModItem>>(
        future: db.listMods(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No mods found.'));
          }
          final mods = snapshot.data!;
          final items = <dynamic>[];
          for (int i = 0; i < mods.length; i++) {
            items.add(mods[i]);
            if (i % _nativeAdFrequency == 0 && i != 0) {
              _loadNativeAd(i);
              final adIndex = i ~/ _nativeAdFrequency - 1;
              if (adIndex < _nativeAds.length) {
                items.insert(i + 1, _nativeAds[adIndex]);
              }
            }
          }
          return Column(
            children: [
              Expanded(
                child: ModList(
                  mods: items,
                  searchQuery: widget.searchQuery,
                ),
              ),
              if (_bannerAd != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: SizedBox(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
