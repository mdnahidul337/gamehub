import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../config/ad_config.dart';
import '../models/coin_package.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import 'purchase_history_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
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
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final db = Provider.of<DBService>(context, listen: false);

    final coinPackages = [
      CoinPackage(coins: 100, price: 50),
      CoinPackage(coins: 160, price: 75),
      CoinPackage(coins: 200, price: 90),
      CoinPackage(coins: 260, price: 110),
      CoinPackage(coins: 500, price: 300),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const PurchaseHistoryScreen(),
              ));
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text('Coins: ${auth.currentUser?.coins ?? 0}'),
            ),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: InkWell(
              onTap: !_isRewardedAdReady
                  ? null
                  : () {
                      _rewardedAd?.fullScreenContentCallback =
                          FullScreenContentCallback(
                        onAdDismissedFullScreenContent: (ad) {
                          _loadRewardedAd();
                        },
                      );
                      _rewardedAd?.show(onUserEarnedReward: (_, reward) {
                        db.watchAdAndAward(auth.currentUser!.uid, 5)
                            .then((awarded) {
                          if (awarded) {
                            auth.refreshCurrentUser();
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('5 coins awarded!')));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Ad failed to load.')));
                          }
                        });
                      });
                    },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.movie, size: 50),
                  SizedBox(height: 8),
                  Text('Watch Ad'),
                  Text('Get 5 free coins'),
                ],
              ),
            ),
          ),
          ...coinPackages.map((pkg) {
            return Card(
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                            package: pkg,
                            auth: auth,
                            db: db,
                          )));
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${pkg.coins} Coins',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${pkg.price} ${pkg.currency}'),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  final CoinPackage package;
  final AuthService auth;
  final DBService db;

  const PaymentScreen(
      {super.key, required this.package, required this.auth, required this.db});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  String _mobileNumber = '';
  String _transactionId = '';
  String _paymentMethod = 'bkash';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buy ${widget.package.coins} Coins'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount: ${widget.package.price} ${widget.package.currency}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Select Payment Method:'),
              Row(
                children: [
                  Radio(
                    value: 'bkash',
                    groupValue: _paymentMethod,
                    onChanged: (value) =>
                        setState(() => _paymentMethod = value!),
                  ),
                  const Text('bKash'),
                  Radio(
                    value: 'nagad',
                    groupValue: _paymentMethod,
                    onChanged: (value) =>
                        setState(() => _paymentMethod = value!),
                  ),
                  const Text('Nagad'),
                  Radio(
                    value: 'gpay',
                    groupValue: _paymentMethod,
                    onChanged: (value) =>
                        setState(() => _paymentMethod = value!),
                  ),
                  const Text('GPay'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Pay to: 01234567890 ($_paymentMethod)'),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                  'Note: Please make the payment first and then submit the details.'),
              const SizedBox(height: 16),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Your Mobile Number'),
                onSaved: (v) => _mobileNumber = v ?? '',
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Transaction ID (TxID)'),
                onSaved: (v) => _transactionId = v ?? '',
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final result = await widget.db.submitPayment(
                      widget.auth.currentUser!.uid,
                      widget.auth.currentUser!.username,
                      widget.package,
                      _mobileNumber,
                      _transactionId,
                      _paymentMethod,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'])),
                    );
                    if (result['success']) {
                      Navigator.of(context).pop();
                    }
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
