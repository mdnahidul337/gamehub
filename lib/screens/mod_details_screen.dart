import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/mod_item.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/download_service.dart';
import '../utils/theme.dart';
import '../widgets/reviews_section.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';

class ModDetailsScreen extends StatefulWidget {
  final ModItem mod;

  const ModDetailsScreen({super.key, required this.mod});

  @override
  _ModDetailsScreenState createState() => _ModDetailsScreenState();
}

class _ModDetailsScreenState extends State<ModDetailsScreen> {
  late Future<bool> _isPurchasedFuture;
  bool _downloadFailed = false;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _checkIfPurchased();
    _loadBannerAd();
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

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }


  void _checkIfPurchased() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final db = Provider.of<DBService>(context, listen: false);
    if (auth.currentUser != null) {
      _isPurchasedFuture =
          db.hasUserPurchased(auth.currentUser!.uid, widget.mod.id!);
    } else {
      _isPurchasedFuture = Future.value(false);
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.mod.title,
                  style: AppTheme.textTheme.headlineMedium
                      ?.copyWith(color: AppTheme.white)),
              background: Hero(
                tag: widget.mod.id!,
                child: CachedNetworkImage(
                  imageUrl: widget.mod.screenshots.isNotEmpty
                      ? widget.mod.screenshots.first
                      : '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Container(
                    color: AppTheme.lightGray,
                    child: const Icon(Icons.image_not_supported,
                        color: AppTheme.grayText),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('About this mod',
                              style: AppTheme.textTheme.headlineMedium),
                          const SizedBox(height: 8),
                          Text(widget.mod.about,
                              style: AppTheme.textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildPurchaseSection(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (widget.mod.id != null)
                    ReviewsSection(modId: widget.mod.id!),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseSection() {
    final auth = Provider.of<AuthService>(context);
    final db = Provider.of<DBService>(context, listen: false);
    final downloadService = Provider.of<DownloadService>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price: ${widget.mod.price} coins',
            style: AppTheme.textTheme.headlineMedium),
        const SizedBox(height: 20),
        if (auth.currentUser != null)
          FutureBuilder<bool>(
            future: _isPurchasedFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final isPurchased = snapshot.data ?? false;
              if (isPurchased || widget.mod.price == 0) {
                if (_downloadFailed) {
                  return ElevatedButton(
                    onPressed: () => _launchURL(widget.mod.fileUrl!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.mainBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                    ),
                    child: const Text('Open Link'),
                  );
                } else {
                  return ElevatedButton(
                    onPressed: () async {
                      try {
                        await downloadService.download(
                          widget.mod.id!,
                          widget.mod.fileUrl!,
                          widget.mod.title,
                          widget.mod.category,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Download started...')),
                        );
                      } catch (e) {
                        setState(() {
                          _downloadFailed = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Download failed: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.mainBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                    ),
                    child: const Text('Download'),
                  );
                }

              } else {
                return ElevatedButton(
                  onPressed: () async {
                    final result = await db.purchaseMod(auth.currentUser!.uid,
                        widget.mod.id!, widget.mod.price);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'])),
                    );
                    if (result['success'] == true) {
                      setState(() {
                        _isPurchasedFuture = Future.value(true);
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mainBlue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                  child: Text('Buy for ${widget.mod.price} coins'),
                );
              }
            },
          ),
      ],
    );
  }
}
