class CoinPackage {
  final int coins;
  final double price;
  final String currency;

  CoinPackage({
    required this.coins,
    required this.price,
    this.currency = 'Taka',
  });

  // 👇 ADD THIS METHOD
  /// Converts this CoinPackage instance into a Map.
  Map<String, dynamic> toMap() {
    return {
      'coins': coins,
      'price': price,
      'currency': currency,
    };
  }

  // 👇 (Recommended) ADD THIS FACTORY CONSTRUCTOR
  /// Creates a CoinPackage instance from a Map.
  factory CoinPackage.fromMap(Map<String, dynamic> map) {
    return CoinPackage(
      coins: map['coins'] as int,
      // Use 'num' to safely cast from either int or double
      price: (map['price'] as num).toDouble(), 
      currency: map['currency'] as String,
    );
  }
}