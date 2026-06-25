import '../models/tile.dart';
import '../models/meld.dart';

class AIHelper {
  // Finds all individual valid melds (runs and groups) that can be made from the hand
  static List<Meld> findAllPossibleMelds(List<Tile> hand) {
    final List<Meld> possibleMelds = [];
    final jokers = hand.where((t) => t.isJoker).toList();

    // 1. Generate Groups
    for (int num = 1; num <= 13; num++) {
      final matchingTiles = hand.where((t) => !t.isJoker && t.number == num).toList();
      if (matchingTiles.isEmpty && jokers.isEmpty) continue;

      // We want to form groups of size 3 and 4
      final List<List<Tile>> groupCandidates = [];
      _generateGroupCombinations(matchingTiles, jokers, 0, [], groupCandidates);

      for (var candidate in groupCandidates) {
        final meld = Meld(candidate);
        if (meld.isValidGroup) {
          possibleMelds.add(meld);
        }
      }
    }

    // 2. Generate Runs
    for (var color in TileColor.values) {
      final colorTiles = hand.where((t) => !t.isJoker && t.color == color).toList();
      if (colorTiles.isEmpty && jokers.isEmpty) continue;

      // Group normal tiles of this color by number for quick lookup
      final Map<int, List<Tile>> tilesByNumber = {};
      for (var tile in colorTiles) {
        tilesByNumber.putIfAbsent(tile.number!, () => []).add(tile);
      }

      // Try every possible start number and run length
      for (int start = 1; start <= 11; start++) {
        for (int len = 3; len <= (14 - start); len++) {
          final List<List<Tile>> runCandidates = [];
          _generateRunCombinations(
            start,
            start + len - 1,
            tilesByNumber,
            jokers,
            0,
            [],
            runCandidates,
          );

          for (var candidate in runCandidates) {
            final meld = Meld(candidate);
            if (meld.isValidRun) {
              possibleMelds.add(meld);
            }
          }
        }
      }
    }

    return possibleMelds;
  }

  static void _generateGroupCombinations(
    List<Tile> matchingTiles,
    List<Tile> jokers,
    int idx,
    List<Tile> current,
    List<List<Tile>> results,
  ) {
    if (current.length >= 3 && current.length <= 4) {
      results.add(List.from(current));
    }
    if (current.length == 4) return;

    // Option A: Add a normal tile from matchingTiles (starting from idx to avoid duplicate subsets)
    for (int i = idx; i < matchingTiles.length; i++) {
      // Avoid duplicate colors in the current candidate (unless we are testing if it's invalid,
      // but since we want to find VALID ones, let's prune early)
      final tile = matchingTiles[i];
      if (current.any((t) => !t.isJoker && t.color == tile.color)) continue;

      current.add(tile);
      _generateGroupCombinations(matchingTiles, jokers, i + 1, current, results);
      current.removeLast();
    }

    // Option B: Add a Joker
    // Since Jokers are identical in value, we only use them by their index to avoid permutations
    final usedJokersCount = current.where((t) => t.isJoker).length;
    if (usedJokersCount < jokers.length) {
      final nextJoker = jokers[usedJokersCount];
      current.add(nextJoker);
      _generateGroupCombinations(matchingTiles, jokers, idx, current, results);
      current.removeLast();
    }
  }

  static void _generateRunCombinations(
    int currentNum,
    int endNum,
    Map<int, List<Tile>> tilesByNumber,
    List<Tile> jokers,
    int usedJokers,
    List<Tile> current,
    List<List<Tile>> results,
  ) {
    if (currentNum > endNum) {
      results.add(List.from(current));
      return;
    }

    // Try normal tiles for this number
    final tilesForNum = tilesByNumber[currentNum] ?? [];
    for (var tile in tilesForNum) {
      current.add(tile);
      _generateRunCombinations(
        currentNum + 1,
        endNum,
        tilesByNumber,
        jokers,
        usedJokers,
        current,
        results,
      );
      current.removeLast();
    }

    // Try Joker
    if (usedJokers < jokers.length) {
      current.add(jokers[usedJokers]);
      _generateRunCombinations(
        currentNum + 1,
        endNum,
        tilesByNumber,
        jokers,
        usedJokers + 1,
        current,
        results,
      );
      current.removeLast();
    }
  }

  // Set Packing / Exact Cover search:
  // Finds combinations of disjoint melds that can be built from the hand.
  // Returns all possible sets of disjoint melds.
  static List<List<Meld>> findDisjointMeldCombinations(List<Tile> hand) {
    final possibleMelds = findAllPossibleMelds(hand);
    final List<List<Meld>> allSolutions = [];

    _backtrackDisjoint(0, hand, possibleMelds, [], allSolutions);
    return allSolutions;
  }

  static void _backtrackDisjoint(
    int startIdx,
    List<Tile> remainingTiles,
    List<Meld> possibleMelds,
    List<Meld> currentChoice,
    List<List<Meld>> allSolutions,
  ) {
    if (currentChoice.isNotEmpty) {
      allSolutions.add(List.from(currentChoice));
    }

    for (int i = startIdx; i < possibleMelds.length; i++) {
      final meld = possibleMelds[i];
      if (_canFormMeld(meld, remainingTiles)) {
        final nextRemaining = _removeTiles(remainingTiles, meld.tiles);
        currentChoice.add(meld);
        _backtrackDisjoint(i + 1, nextRemaining, possibleMelds, currentChoice, allSolutions);
        currentChoice.removeLast();
      }
    }
  }

  static bool _canFormMeld(Meld meld, List<Tile> pool) {
    final poolIds = pool.map((t) => t.id).toSet();
    return meld.tiles.every((tile) => poolIds.contains(tile.id));
  }

  static List<Tile> _removeTiles(List<Tile> pool, List<Tile> toRemove) {
    final toRemoveIds = toRemove.map((t) => t.id).toSet();
    return pool.where((t) => !toRemoveIds.contains(t.id)).toList();
  }
}
