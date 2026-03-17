/// Represents the different continents available in the game
enum Continent {
  asia(
    displayName: 'Asia',
    flagEmoji: '🌏',
    description: 'The largest continent, home to diverse wildlife',
  ),
  africa(
    displayName: 'Africa',
    flagEmoji: '🌍',
    description: 'Rich biodiversity across savannas and rainforests',
  ),
  europe(
    displayName: 'Europe',
    flagEmoji: '🌍',
    description: 'Varied ecosystems from Mediterranean to Arctic',
  ),
  northAmerica(
    displayName: 'North & Central America',
    flagEmoji: '🌎',
    description: 'From tropical rainforests to frozen tundras',
  ),
  southAmerica(
    displayName: 'South America',
    flagEmoji: '🌎',
    description: 'The Amazon rainforest and Andean highlands',
  ),
  australia(
    displayName: 'Australia',
    flagEmoji: '🦘',
    description: 'Unique marsupials and endemic species',
  );

  const Continent({
    required this.displayName,
    required this.flagEmoji,
    required this.description,
  });

  final String displayName;
  final String flagEmoji;
  final String description;

  /// Get all continents except Antarctica (not included)
  static List<Continent> get allContinents => Continent.values;

  /// Get the default continent (Asia - current default)
  static Continent get defaultContinent => Continent.asia;
}

/// Extension to help with continent selection
extension ContinentExtension on Continent {
  /// Returns a short code for the continent
  String get code {
    switch (this) {
      case Continent.asia:
        return 'asia';
      case Continent.africa:
        return 'africa';
      case Continent.europe:
        return 'europe';
      case Continent.northAmerica:
        return 'na';
      case Continent.southAmerica:
        return 'sa';
      case Continent.australia:
        return 'aus';
    }
  }

  /// Returns the asset folder path for animals of this continent
  String get animalAssetFolder => 'assets/animals/$code/';

  /// Returns the asset folder path for seeds of this continent
  String get seedAssetFolder => 'assets/seeds/$code/';
}

