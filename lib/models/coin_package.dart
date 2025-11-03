class CoinPackage {
  final int coins;
  final double price;
  final String currency;

  CoinPackage({
    required this.coins,
    required this.price,
    this.currency = 'Taka',
  });
}
