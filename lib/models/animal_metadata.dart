import 'package:flutter/material.dart';
import 'continent.dart';

enum AnimalSize { small, medium, big }

enum AnimalRarity { common, rare, special }

enum SpawnDistribution { high, medium, low }

enum AnimalHabitat { land, air, marine }

class AnimalMetadata {
  final String id;
  final String name;
  final AnimalSize appearingSize;
  final AnimalRarity rarity;
  final SpawnDistribution spawningDistribution;
  final AnimalHabitat habitat;
  final Continent continent;
  final int xpWhenCaught;

  const AnimalMetadata({
    required this.id,
    required this.name,
    required this.appearingSize,
    required this.rarity,
    required this.spawningDistribution,
    required this.habitat,
    this.continent = Continent.asia,
    required this.xpWhenCaught,
  });
}

const Map<String, AnimalMetadata> kAnimalMetadataByName = {
  'ladybug': AnimalMetadata(
    id: '001',
    name: 'ladybug',
    appearingSize: AnimalSize.small,
    rarity: AnimalRarity.common,
    spawningDistribution: SpawnDistribution.high,
    habitat: AnimalHabitat.land,
    xpWhenCaught: 5,
  ),
  'ant': AnimalMetadata(
    id: '002',
    name: 'ant',
    appearingSize: AnimalSize.small,
    rarity: AnimalRarity.common,
    spawningDistribution: SpawnDistribution.high,
    habitat: AnimalHabitat.land,
    xpWhenCaught: 5,
  ),
  'bat': AnimalMetadata(
    id: '003',
    name: 'bat',
    appearingSize: AnimalSize.medium,
    rarity: AnimalRarity.rare,
    spawningDistribution: SpawnDistribution.medium,
    habitat: AnimalHabitat.air,
    xpWhenCaught: 20,
  ),
  'buffalo': AnimalMetadata(
    id: '004',
    name: 'buffalo',
    appearingSize: AnimalSize.big,
    rarity: AnimalRarity.special,
    spawningDistribution: SpawnDistribution.low,
    habitat: AnimalHabitat.land,
    xpWhenCaught: 100,
  ),
  'butterfly': AnimalMetadata(
    id: '005',
    name: 'butterfly',
    appearingSize: AnimalSize.small,
    rarity: AnimalRarity.common,
    spawningDistribution: SpawnDistribution.high,
    habitat: AnimalHabitat.air,
    xpWhenCaught: 5,
  ),
  'dragonfly': AnimalMetadata(
    id: '006',
    name: 'dragonfly',
    appearingSize: AnimalSize.small,
    rarity: AnimalRarity.common,
    spawningDistribution: SpawnDistribution.high,
    habitat: AnimalHabitat.air,
    xpWhenCaught: 5,
  ),
  'frog': AnimalMetadata(
    id: '007',
    name: 'frog',
    appearingSize: AnimalSize.medium,
    rarity: AnimalRarity.rare,
    spawningDistribution: SpawnDistribution.medium,
    habitat: AnimalHabitat.land,
    xpWhenCaught: 20,
  ),
  'gecko': AnimalMetadata(
    id: '008',
    name: 'gecko',
    appearingSize: AnimalSize.medium,
    rarity: AnimalRarity.common,
    spawningDistribution: SpawnDistribution.high,
    habitat: AnimalHabitat.land,
    xpWhenCaught: 5,
  ),
  'giant_hornet': AnimalMetadata(
    id: '009',
    name: 'giant_hornet',
    appearingSize: AnimalSize.small,
    rarity: AnimalRarity.rare,
    spawningDistribution: SpawnDistribution.medium,
    habitat: AnimalHabitat.air,
    xpWhenCaught: 20,
  ),
  'grasshopper': AnimalMetadata(
    id: '010',
    name: 'grasshopper',
    appearingSize: AnimalSize.small,
    rarity: AnimalRarity.common,
    spawningDistribution: SpawnDistribution.high,
    habitat: AnimalHabitat.land,
    xpWhenCaught: 5,
  ),
  'jumping_spider': AnimalMetadata(
    id: '011',
    name: 'jumping_spider',
    appearingSize: AnimalSize.small,
    rarity: AnimalRarity.rare,
    spawningDistribution: SpawnDistribution.medium,
    habitat: AnimalHabitat.land,
    xpWhenCaught: 20,
  ),
  'king_cobra': AnimalMetadata(
    id: '012',
    name: 'king_cobra',
    appearingSize: AnimalSize.big,
    rarity: AnimalRarity.special,
    spawningDistribution: SpawnDistribution.low,
    habitat: AnimalHabitat.land,
    xpWhenCaught: 100,
  ),
  'kingfisher': AnimalMetadata(
    id: '013',
    name: 'kingfisher',
    appearingSize: AnimalSize.medium,
    rarity: AnimalRarity.rare,
    spawningDistribution: SpawnDistribution.medium,
    habitat: AnimalHabitat.marine,
    xpWhenCaught: 20,
  ),
  'macaque': AnimalMetadata(
    id: '014',
    name: 'macaque',
    appearingSize: AnimalSize.medium,
    rarity: AnimalRarity.rare,
    spawningDistribution: SpawnDistribution.medium,
    habitat: AnimalHabitat.land,
    xpWhenCaught: 20,
  ),
  'mosquito': AnimalMetadata(
    id: '015',
    name: 'mosquito',
    appearingSize: AnimalSize.small,
    rarity: AnimalRarity.common,
    spawningDistribution: SpawnDistribution.high,
    habitat: AnimalHabitat.air,
    xpWhenCaught: 5,
  ),
  'pangolin': AnimalMetadata(
    id: '016',
    name: 'pangolin',
    appearingSize: AnimalSize.medium,
    rarity: AnimalRarity.special,
    spawningDistribution: SpawnDistribution.low,
    habitat: AnimalHabitat.land,
    xpWhenCaught: 100,
  ),
  'praying_mantis': AnimalMetadata(
    id: '017',
    name: 'praying_mantis',
    appearingSize: AnimalSize.small,
    rarity: AnimalRarity.rare,
    spawningDistribution: SpawnDistribution.medium,
    habitat: AnimalHabitat.land,
    xpWhenCaught: 20,
  ),
  'rat': AnimalMetadata(
    id: '018',
    name: 'rat',
    appearingSize: AnimalSize.medium,
    rarity: AnimalRarity.common,
    spawningDistribution: SpawnDistribution.high,
    habitat: AnimalHabitat.marine,
    xpWhenCaught: 5,
  ),
  'scorpion': AnimalMetadata(
    id: '019',
    name: 'scorpion',
    appearingSize: AnimalSize.medium,
    rarity: AnimalRarity.rare,
    spawningDistribution: SpawnDistribution.medium,
    habitat: AnimalHabitat.land,
    xpWhenCaught: 20,
  ),
  'squirrel': AnimalMetadata(
    id: '020',
    name: 'squirrel',
    appearingSize: AnimalSize.medium,
    rarity: AnimalRarity.common,
    spawningDistribution: SpawnDistribution.high,
    habitat: AnimalHabitat.land,
    xpWhenCaught: 5,
  ),
};

double getAnimalMapSizeMultiplier(String animalName) {
  final size = kAnimalMetadataByName[animalName]?.appearingSize;
  switch (size) {
    case AnimalSize.medium:
      return 2.0; // Medium - unchanged
    case AnimalSize.big:
      return 3.0 * 0.8; // Big - 80% of current (was 3.0, now 2.4)
    case AnimalSize.small:
      return 1.5 * 1.25; // Small - 125% of current (was 1.5, now 1.875)
    default:
      return 1.5 * 1.25; // Default to small size (125%)
  }
}

/// Returns the size multiplier for seeds on the map
/// All seeds are 125% of their current size
double getSeedMapSizeMultiplier(String seedName) {
  // All seeds get 125% of current size (current base is 1.0)
  return 1.0 * 1.25; // 1.25
}

int getAnimalSpawnWeight(String animalName) {
  final distribution = kAnimalMetadataByName[animalName]?.spawningDistribution;
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

Color getRarityBorderColor(AnimalRarity rarity) {
  switch (rarity) {
    case AnimalRarity.rare:
      return const Color(0xFF2196F3);
    case AnimalRarity.special:
      return const Color(0xFFFFC107);
    case AnimalRarity.common:
      return const Color(0xFF9E9E9E);
  }
}
