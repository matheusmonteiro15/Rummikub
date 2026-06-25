import 'tile.dart';

enum AILevel { easy, medium, hard }

class Player {
  final String id;
  final String name;
  final bool isHuman;
  final AILevel? aiLevel;
  final List<Tile> tiles;
  final bool hasMadeInitialMeld;

  Player({
    required this.id,
    required this.name,
    required this.isHuman,
    this.aiLevel,
    List<Tile>? tiles,
    this.hasMadeInitialMeld = false,
  }) : tiles = List.unmodifiable(tiles ?? []);

  Player copyWith({
    String? id,
    String? name,
    bool? isHuman,
    AILevel? aiLevel,
    List<Tile>? tiles,
    bool? hasMadeInitialMeld,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      isHuman: isHuman ?? this.isHuman,
      aiLevel: aiLevel ?? this.aiLevel,
      tiles: tiles != null ? List.unmodifiable(tiles) : this.tiles,
      hasMadeInitialMeld: hasMadeInitialMeld ?? this.hasMadeInitialMeld,
    );
  }

  @override
  String toString() {
    final role = isHuman ? 'Humano' : 'Bot-${aiLevel.toString().split('.').last}';
    return '$name ($role) [${tiles.length} peças]';
  }
}
