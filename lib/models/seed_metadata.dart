import 'package:flutter/material.dart';
import 'continent.dart';
import 'animal_metadata.dart';

enum SeedRarity { common, rare, special }

class SeedMetadata {
  final String id; // matches Collection tab order (001, 002, ...)
  final String name; // asset/name id (e.g. 'barley')
  final SeedRarity rarity;
  final Continent continent;
  final Duration baseGrowthTime;
  final int xpWhenCollected;
  final int xpWhenHarvested;
  final SpawnDistribution spawnChance;

  const SeedMetadata({
    required this.id,
    required this.name,
    required this.rarity,
    required this.continent,
    required this.baseGrowthTime,
    required this.xpWhenCollected,
    required this.xpWhenHarvested,
    required this.spawnChance,
  });
}

const Map<String, SeedMetadata> kSeedMetadataByName = {
  // Order matches CollectionScreen.seeds
  'barley': SeedMetadata(
    id: '001',
    name: 'barley',
    rarity: SeedRarity.common,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 5),
    xpWhenCollected: 1,
    xpWhenHarvested: 5,
    spawnChance: SpawnDistribution.high,
  ),
  'pineapple': SeedMetadata(
    id: '002',
    name: 'pineapple',
    rarity: SeedRarity.special,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 60),
    xpWhenCollected: 25,
    xpWhenHarvested: 100,
    spawnChance: SpawnDistribution.low,
  ),
  'basil': SeedMetadata(
    id: '003',
    name: 'basil',
    rarity: SeedRarity.common,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 5),
    xpWhenCollected: 1,
    xpWhenHarvested: 5,
    spawnChance: SpawnDistribution.high,
  ),
  'chili': SeedMetadata(
    id: '004',
    name: 'chili',
    rarity: SeedRarity.common,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 5),
    xpWhenCollected: 1,
    xpWhenHarvested: 5,
    spawnChance: SpawnDistribution.high,
  ),
  'coriander': SeedMetadata(
    id: '005',
    name: 'coriander',
    rarity: SeedRarity.common,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 5),
    xpWhenCollected: 1,
    xpWhenHarvested: 5,
    spawnChance: SpawnDistribution.high,
  ),
  'corn': SeedMetadata(
    id: '006',
    name: 'corn',
    rarity: SeedRarity.common,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 5),
    xpWhenCollected: 1,
    xpWhenHarvested: 5,
    spawnChance: SpawnDistribution.high,
  ),
  'durian': SeedMetadata(
    id: '007',
    name: 'durian',
    rarity: SeedRarity.rare,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 15),
    xpWhenCollected: 5,
    xpWhenHarvested: 20,
    spawnChance: SpawnDistribution.medium,
  ),
  'eggplant': SeedMetadata(
    id: '008',
    name: 'eggplant',
    rarity: SeedRarity.common,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 5),
    xpWhenCollected: 1,
    xpWhenHarvested: 5,
    spawnChance: SpawnDistribution.high,
  ),
  'jackfruit': SeedMetadata(
    id: '009',
    name: 'jackfruit',
    rarity: SeedRarity.rare,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 15),
    xpWhenCollected: 5,
    xpWhenHarvested: 20,
    spawnChance: SpawnDistribution.medium,
  ),
  'lotus': SeedMetadata(
    id: '010',
    name: 'lotus',
    rarity: SeedRarity.rare,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 15),
    xpWhenCollected: 5,
    xpWhenHarvested: 20,
    spawnChance: SpawnDistribution.medium,
  ),
  'mango': SeedMetadata(
    id: '011',
    name: 'mango',
    rarity: SeedRarity.common,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 5),
    xpWhenCollected: 1,
    xpWhenHarvested: 5,
    spawnChance: SpawnDistribution.high,
  ),
  'mustard': SeedMetadata(
    id: '012',
    name: 'mustard',
    rarity: SeedRarity.common,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 5),
    xpWhenCollected: 1,
    xpWhenHarvested: 5,
    spawnChance: SpawnDistribution.high,
  ),
  'peanut': SeedMetadata(
    id: '013',
    name: 'peanut',
    rarity: SeedRarity.common,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 5),
    xpWhenCollected: 1,
    xpWhenHarvested: 5,
    spawnChance: SpawnDistribution.high,
  ),
  'rambutan': SeedMetadata(
    id: '014',
    name: 'rambutan',
    rarity: SeedRarity.rare,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 15),
    xpWhenCollected: 5,
    xpWhenHarvested: 20,
    spawnChance: SpawnDistribution.medium,
  ),
  'rice': SeedMetadata(
    id: '015',
    name: 'rice',
    rarity: SeedRarity.common,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 5),
    xpWhenCollected: 1,
    xpWhenHarvested: 5,
    spawnChance: SpawnDistribution.high,
  ),
  'sesame': SeedMetadata(
    id: '016',
    name: 'sesame',
    rarity: SeedRarity.common,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 5),
    xpWhenCollected: 1,
    xpWhenHarvested: 5,
    spawnChance: SpawnDistribution.high,
  ),
  'soybean': SeedMetadata(
    id: '017',
    name: 'soybean',
    rarity: SeedRarity.common,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 5),
    xpWhenCollected: 1,
    xpWhenHarvested: 5,
    spawnChance: SpawnDistribution.high,
  ),
  'strawberry': SeedMetadata(
    id: '018',
    name: 'strawberry',
    rarity: SeedRarity.common,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 5),
    xpWhenCollected: 1,
    xpWhenHarvested: 5,
    spawnChance: SpawnDistribution.high,
  ),
  'tamarind': SeedMetadata(
    id: '019',
    name: 'tamarind',
    rarity: SeedRarity.common,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 5),
    xpWhenCollected: 1,
    xpWhenHarvested: 5,
    spawnChance: SpawnDistribution.high,
  ),
  'watermelon': SeedMetadata(
    id: '020',
    name: 'watermelon',
    rarity: SeedRarity.common,
    continent: Continent.asia,
    baseGrowthTime: Duration(minutes: 5),
    xpWhenCollected: 1,
    xpWhenHarvested: 5,
    spawnChance: SpawnDistribution.high,
  ),
};

int getSeedSpawnWeight(String seedName) {
  final distribution = kSeedMetadataByName[seedName]?.spawnChance;
  switch (distribution) {
    case SpawnDistribution.medium:
      return 4;
    case SpawnDistribution.low:
      return 1;
    case SpawnDistribution.high:
    default:
      return 8;
  }
}

Color getSeedRarityBorderColor(SeedRarity rarity) {
  switch (rarity) {
    case SeedRarity.rare:
      return const Color(0xFF2196F3);
    case SeedRarity.special:
      return const Color(0xFFFFC107);
    case SeedRarity.common:
      return const Color(0xFF9E9E9E);
  }
}
