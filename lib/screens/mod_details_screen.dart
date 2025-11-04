import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/mod_item.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/download_service.dart';
import '../widgets/reviews_section.dart';

class ModDetailsScreen extends StatefulWidget {
  final ModItem mod;

  const ModDetailsScreen({super.key, required this.mod});

  @override
  _ModDetailsScreenState createState() => _ModDetailsScreenState();
}

class _ModDetailsScreenState extends State<ModDetailsScreen> {
  late Future<bool> _isPurchasedFuture;
  bool _downloadFailed = false;

  @override
  void initState() {
    super.initState();
    _checkIfPurchased();
  }

  void _checkIfPurchased() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final db = Provider.of<DBService>(context, listen: false);
    if (auth.currentUser != null) {
      _isPurchasedFuture = db.hasUserPurchased(auth.currentUser!.uid, widget.mod.id!);
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
    final auth = Provider.of<AuthService>(context);
    final db = Provider.of<DBService>(context, listen: false);
    final downloadService = Provider.of<DownloadService>(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.mod.title)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.mod.screenshots.isNotEmpty)
                FadeInImage.assetNetwork(
                placeholder: 'assets/images/placeholder.png',
                image: widget.mod.screenshots.first,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                imageErrorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            Text(widget.mod.title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.mod.about),
            const SizedBox(height: 16),
            Text('Price: ${widget.mod.price} coins'),
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
                              const SnackBar(content: Text('Download started...')),
                            );
                          } catch (e) {
                            setState(() {
                              _downloadFailed = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Download failed: $e')),
                            );
                          }
                        },
                        child: const Text('Download'),
                      );
                    }
                  } else {
                    return ElevatedButton(
                      onPressed: () async {
                        final result = await db.purchaseMod(
                            auth.currentUser!.uid, widget.mod.id!, widget.mod.price);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'])),
                        );
                        if (result['success'] == true) {
                          setState(() {
                            _isPurchasedFuture = Future.value(true);
                          });
                        }
                      },
                      child: Text('Buy for ${widget.mod.price} coins'),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              if (widget.mod.id != null) ReviewsSection(modId: widget.mod.id!),
            ],
          ),
        ),
      ),
    );
  }
}
