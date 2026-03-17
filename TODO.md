# TODO - Continent Feature Implementation

## Overview
Add support for 6 continents (Africa, South America, North/Mid America, Asia, Australia, Europe) with 50 animals and 50 seeds per continent (300 total each).

## Plan

### Phase 1: Data Models
- [ ] 1.1 Create continent enum in lib/models/continent.dart
- [ ] 1.2 Update AnimalMetadata to include continent
- [ ] 1.3 Create SeedMetadata similar to AnimalMetadata with continent

### Phase 2: Game Provider Updates
- [ ] 2.1 Add currentContinent state to GameProvider
- [ ] 2.2 Add continent switching methods
- [ ] 2.3 Add continent-specific unlocked animals/seeds tracking

### Phase 3: Spawn Service Updates
- [ ] 3.1 Update SpawnService to use current continent
- [ ] 3.2 Add continent parameter to spawn generation

### Phase 4: UI Updates
- [ ] 4.1 Update AllMapsScreen with continent selector
- [ ] 4.2 Update CollectionScreen to show continent filter
- [ ] 4.3 Add continent indicator in game HUD

### Phase 5: Asset Organization
- [ ] 5.1 Create asset folder structure for continents
- [ ] 5.2 Define 50 animals per continent (placeholder IDs for now)

## Current Implementation Notes
- 20 animals currently in kAnimalMetadataByName
- All animals are Asia-based (Thai/Koh Samui theme)
- Need to expand to 300 animals and 300 seeds total
