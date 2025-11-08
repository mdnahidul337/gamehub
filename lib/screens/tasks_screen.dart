import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../config/ad_config.dart';

import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../models/task_item.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final DBService _db = DBService();
  late Future<List<TaskItem>> _future;
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _isRewardedAdReady = false;
  bool _isInterstitialAdReady = false;
  bool _hasClaimedDailyBonus = false;

  @override
  void initState() {
    super.initState();
    _future = _db.listTasks();
    _loadRewardedAd();
    _loadInterstitialAd();
    _checkDailyBonusStatus();
  }

  void _checkDailyBonusStatus() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.currentUser?.uid;
    if (uid != null) {
      final hasClaimed = await _db.hasClaimedDailyBonus(uid);
      if (mounted) {
        setState(() {
          _hasClaimedDailyBonus = hasClaimed;
        });
      }
    }
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          setState(() {
            _isRewardedAdReady = true;
          });
        },
        onAdFailedToLoad: (err) {
          print('Failed to load a rewarded ad: ${err.message}');
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          setState(() {
            _isInterstitialAdReady = true;
          });
        },
        onAdFailedToLoad: (err) {
          print('Failed to load an interstitial ad: ${err.message}');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _future = _db.listTasks());
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final uid = auth.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: uid == null ||
                            !_isInterstitialAdReady ||
                            _hasClaimedDailyBonus
                        ? null
                        : () {
                            _interstitialAd?.fullScreenContentCallback =
                                FullScreenContentCallback(
                              onAdDismissedFullScreenContent: (ad) {
                                _db.giveDailyLoginBonus(uid, 2).then((awarded) {
                                  if (awarded) {
                                    auth.refreshCurrentUser();
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Daily login bonus awarded: 2 coins'),
                                    ));
                                    setState(() {
                                      _hasClaimedDailyBonus = true;
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content:
                                          Text('Daily bonus already claimed'),
                                    ));
                                  }
                                });
                                _loadInterstitialAd();
                              },
                            );
                            _interstitialAd?.show();
                          },
                    child: Text(_hasClaimedDailyBonus
                        ? 'Claimed Today'
                        : 'Claim Daily Login (2 coins)'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: uid == null || !_isRewardedAdReady
                      ? null
                      : () {
                          _rewardedAd?.fullScreenContentCallback =
                              FullScreenContentCallback(
                            onAdDismissedFullScreenContent: (ad) {
                              _loadRewardedAd();
                            },
                          );
                          _rewardedAd?.show(onUserEarnedReward: (_, reward) {
                            _db.watchAdAndAward(uid, 2).then((ok) {
                              if (ok) {
                                auth.refreshCurrentUser();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Thanks! +2 coins')));
                              }
                            });
                          });
                        },
                  child: const Text('Watch Ad (+2)'),
                )
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TaskItem>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done)
                  return const Center(child: CircularProgressIndicator());
                final tasks = snap.data ?? [];
                if (tasks.isEmpty)
                  return const Center(child: Text('No tasks found'));
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, i) {
                      final t = tasks[i];
                      return FutureBuilder<bool>(
                        future: uid == null
                            ? Future.value(false)
                            : _db.hasUserCompletedTask(uid, t.id!),
                        builder: (context, csnap) {
                          final completed = csnap.data ?? false;
                          return ListTile(
                            leading: t.thumbnailUrl != null
                                ? Image.network(t.thumbnailUrl!,
                                    width: 48, height: 48, fit: BoxFit.cover)
                                : const Icon(Icons.task),
                            title: Text(t.title),
                            subtitle:
                                Text('${t.points} coins • ${t.description}'),
                            trailing: completed
                                ? const Text('Completed',
                                    style: TextStyle(color: Colors.green))
                                : ElevatedButton(
                                    onPressed: uid == null || !_isRewardedAdReady
                                        ? null
                                        : () {
                                            _rewardedAd?.fullScreenContentCallback =
                                                FullScreenContentCallback(
                                              onAdDismissedFullScreenContent: (ad) {
                                                _loadRewardedAd();
                                              },
                                            );
                                            _rewardedAd?.show(
                                                onUserEarnedReward: (_, reward) {
                                              _db
                                                  .completeTaskForUser(
                                                      uid, t.id!, t.points)
                                                  .then((awarded) {
                                                if (awarded) {
                                                  auth.refreshCurrentUser();
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(SnackBar(
                                                          content: Text(
                                                              'Task completed! +${t.points} coins')));
                                                  _refresh();
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(const SnackBar(
                                                          content: Text(
                                                              'Already completed')));
                                                }
                                              });
                                            });
                                          },
                                    child: const Text('Complete')),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
