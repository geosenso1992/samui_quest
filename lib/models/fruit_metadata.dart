import 'seed_metadata.dart';

class FruitMetadata {
  final String id; // same as the matching seed id
  final String name; // same as the matching seed id
  final SeedRarity rarity;
  final int valueCoinsWhenSold;
  final int xpWhenSold;

  const FruitMetadata({
    required this.id,
    required this.name,
    required this.rarity,
    required this.valueCoinsWhenSold,
    required this.xpWhenSold,
  });
}

const int _commonFruitSellCoins = 5;
const int _rareFruitSellCoins = 20;
const int _specialFruitSellCoins = 100;

// Chosen defaults (can be tweaked later):
// common=1, rare=5, special=25 XP per fruit sold.
const int _commonFruitSellXp = 1;
const int _rareFruitSellXp = 5;
const int _specialFruitSellXp = 25;

FruitMetadata? getFruitMetadata(String fruitId) {
  final seed = kSeedMetadataByName[fruitId];
  if (seed == null) return null;

  final (coins, xp) = switch (seed.rarity) {
    SeedRarity.common => (_commonFruitSellCoins, _commonFruitSellXp),
    SeedRarity.rare => (_rareFruitSellCoins, _rareFruitSellXp),
    SeedRarity.special => (_specialFruitSellCoins, _specialFruitSellXp),
  };

  return FruitMetadata(
    id: seed.id,
    name: fruitId,
    rarity: seed.rarity,
    valueCoinsWhenSold: coins,
    xpWhenSold: xp,
  );
}

int getFruitSellCoins(String fruitId) {
  return getFruitMetadata(fruitId)?.valueCoinsWhenSold ?? 0;
}

int getFruitSellXp(String fruitId) {
  return getFruitMetadata(fruitId)?.xpWhenSold ?? 0;
}

