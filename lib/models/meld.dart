import 'tile.dart';

enum MeldType { run, group, invalid }

class Meld {
  final List<Tile> tiles;

  Meld(List<Tile> tiles) : tiles = List.unmodifiable(tiles);

  MeldType get type {
    if (isValidRun) return MeldType.run;
    if (isValidGroup) return MeldType.group;
    return MeldType.invalid;
  }

  bool get isValid => type != MeldType.invalid;

  bool get isValidGroup {
    if (tiles.length < 3 || tiles.length > 4) return false;

    // Find first non-joker to get the number
    Tile? firstNonJoker;
    for (var tile in tiles) {
      if (!tile.isJoker) {
        firstNonJoker = tile;
        break;
      }
    }

    // If all are jokers (impossible with only 2 jokers)
    if (firstNonJoker == null) return false;

    final targetNumber = firstNonJoker.number;
    final colors = <TileColor>{};

    for (var tile in tiles) {
      if (tile.isJoker) continue;
      if (tile.number != targetNumber) return false;
      if (colors.contains(tile.color)) return false; // Duplicate colors not allowed
      colors.add(tile.color!);
    }

    return true;
  }

  bool get isValidRun {
    if (tiles.length < 3) return false;

    // Find first non-joker
    int firstNonJokerIdx = -1;
    Tile? firstNonJoker;
    for (int i = 0; i < tiles.length; i++) {
      if (!tiles[i].isJoker) {
        firstNonJokerIdx = i;
        firstNonJoker = tiles[i];
        break;
      }
    }

    if (firstNonJoker == null) return false; // All jokers (impossible with 2 jokers)

    final color = firstNonJoker.color;
    final number = firstNonJoker.number!;

    for (int i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      final expectedNumber = number + (i - firstNonJokerIdx);

      // Numbers must be between 1 and 13
      if (expectedNumber < 1 || expectedNumber > 13) return false;

      if (tile.isJoker) continue;

      if (tile.color != color) return false;
      if (tile.number != expectedNumber) return false;
    }

    return true;
  }

  int get points {
    switch (type) {
      case MeldType.group:
        final nonJoker = tiles.firstWhere((t) => !t.isJoker);
        return nonJoker.number! * tiles.length;
      case MeldType.run:
        int firstNonJokerIdx = -1;
        Tile? firstNonJoker;
        for (int i = 0; i < tiles.length; i++) {
          if (!tiles[i].isJoker) {
            firstNonJokerIdx = i;
            firstNonJoker = tiles[i];
            break;
          }
        }
        if (firstNonJoker == null) return 0;
        final baseNumber = firstNonJoker.number!;
        int sum = 0;
        for (int i = 0; i < tiles.length; i++) {
          sum += baseNumber + (i - firstNonJokerIdx);
        }
        return sum;
      case MeldType.invalid:
        return 0;
    }
  }

  // Helper to get what a Joker represents in this meld
  Map<int, Tile> getJokerRepresentations() {
    final Map<int, Tile> representations = {};
    if (!isValid) return representations;

    if (type == MeldType.group) {
      final nonJoker = tiles.firstWhere((t) => !t.isJoker);
      final num = nonJoker.number!;
      final usedColors = tiles.where((t) => !t.isJoker).map((t) => t.color!).toSet();
      final unusedColors = TileColor.values.where((c) => !usedColors.contains(c)).toList();

      int unusedIdx = 0;
      for (int i = 0; i < tiles.length; i++) {
        if (tiles[i].isJoker) {
          final color = unusedIdx < unusedColors.length ? unusedColors[unusedIdx++] : TileColor.red;
          representations[i] = Tile.normal('${tiles[i].id}_rep', num, color);
        }
      }
    } else if (type == MeldType.run) {
      int firstNonJokerIdx = -1;
      Tile? firstNonJoker;
      for (int i = 0; i < tiles.length; i++) {
        if (!tiles[i].isJoker) {
          firstNonJokerIdx = i;
          firstNonJoker = tiles[i];
          break;
        }
      }
      if (firstNonJoker != null) {
        final color = firstNonJoker.color!;
        final baseNumber = firstNonJoker.number!;
        for (int i = 0; i < tiles.length; i++) {
          if (tiles[i].isJoker) {
            final expectedNumber = baseNumber + (i - firstNonJokerIdx);
            representations[i] = Tile.normal('${tiles[i].id}_rep', expectedNumber, color);
          }
        }
      }
    }
    return representations;
  }
}
