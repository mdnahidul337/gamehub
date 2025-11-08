import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/mod_item.dart';
import 'native_ad_widget.dart';
import '../screens/mod_details_screen.dart';
import '../utils/theme.dart';

class ModList extends StatelessWidget {
  final List<dynamic> mods;
  final String searchQuery;

  const ModList({super.key, required this.mods, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final filteredMods = mods.where((mod) {
      if (mod is ModItem) {
        return mod.title.toLowerCase().contains(searchQuery.toLowerCase());
      }
      return true;
    }).toList();

    if (filteredMods.isEmpty) {
      return const Center(child: Text('No mods found.'));
    }

    return ListView.builder(
      itemCount: filteredMods.length,
      itemBuilder: (context, index) {
        final item = filteredMods[index];
        if (item is ModItem) {
          return _buildItemCard(context, item);
        } else if (item is NativeAd) {
          return NativeAdWidget(ad: item);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildItemCard(BuildContext context, ModItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ModDetailsScreen(mod: item),
        ));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                AppTheme.white,
                AppTheme.lightGray.withOpacity(0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.screenshots.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: item.screenshots.first,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGray,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: AppTheme.grayText,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTheme.textTheme.headlineMedium?.copyWith(
                        color: Colors.black,
                        fontSize: 20,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.publisherName,
                          style: AppTheme.textTheme.bodyMedium,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.download,
                              color: AppTheme.grayText,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.downloads}',
                              style: AppTheme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
