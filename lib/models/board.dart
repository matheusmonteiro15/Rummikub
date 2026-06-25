import 'meld.dart';
import 'tile.dart';

class Board {
  final List<Meld> melds;

  Board({List<Meld>? melds}) : melds = List.unmodifiable(melds ?? []);

  factory Board.empty() => Board(melds: []);

  bool get isValid {
    if (melds.isEmpty) return true;
    return melds.every((meld) => meld.isValid);
  }

  bool containsTile(Tile tile) {
    return melds.any((m) => m.tiles.contains(tile));
  }

  List<Tile> get allTiles {
    return melds.expand((m) => m.tiles).toList();
  }

  Board copyWith({List<Meld>? melds}) {
    return Board(
      melds: melds ?? this.melds,
    );
  }

  @override
  String toString() {
    return melds.map((m) => m.tiles.toString()).join('\n');
  }
}
