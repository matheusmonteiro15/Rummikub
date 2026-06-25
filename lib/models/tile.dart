enum TileColor { red, blue, yellow, black }

class Tile {
  final String id;
  final int? number; // 1-13, null for Joker
  final TileColor? color; // null for Joker
  final bool isJoker;

  Tile({
    required this.id,
    this.number,
    this.color,
    this.isJoker = false,
  }) : assert(isJoker || (number != null && color != null),
            'Non-joker tiles must have a number and color');

  factory Tile.normal(String id, int number, TileColor color) {
    return Tile(id: id, number: number, color: color, isJoker: false);
  }

  factory Tile.joker(String id) {
    return Tile(id: id, isJoker: true);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    if (isJoker) return '🃏';
    final colorStr = color.toString().split('.').last.toUpperCase();
    return '$colorStr-$number';
  }

  // Helper to copy a tile
  Tile copyWith({
    String? id,
    int? number,
    TileColor? color,
    bool? isJoker,
  }) {
    return Tile(
      id: id ?? this.id,
      number: isJoker == true ? null : (number ?? this.number),
      color: isJoker == true ? null : (color ?? this.color),
      isJoker: isJoker ?? this.isJoker,
    );
  }
}
