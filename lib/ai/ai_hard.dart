import '../models/tile.dart';
import '../models/meld.dart';
import '../models/board.dart';
import 'ai_base.dart';
import 'ai_helper.dart';

class AIHard extends AIBase {
  // Limit search steps to prevent performance issues
  static const int maxSearchSteps = 2000;
  int _searchSteps = 0;

  @override
  MapEntry<Board, List<Tile>>? playTurn(
    Board currentBoard,
    List<Tile> hand,
    bool hasMadeInitialMeld,
  ) {
    if (!hasMadeInitialMeld) {
      // Must open with >= 30 points using only hand tiles
      final combinations = AIHelper.findDisjointMeldCombinations(hand);
      final validOpenings = combinations.where((comb) {
        int sum = comb.fold(0, (s, meld) => s + meld.points);
        return sum >= 30;
      }).toList();

      if (validOpenings.isEmpty) return null;

      // Pick the opening that plays the most tiles
      validOpenings.sort((a, b) {
        final tilesA = a.fold(0, (sum, m) => sum + m.tiles.length);
        final tilesB = b.fold(0, (sum, m) => sum + m.tiles.length);
        return tilesB.compareTo(tilesA);
      });

      final chosenComb = validOpenings.first;
      return _applyMeldsToBoard(currentBoard, hand, chosenComb);
    }

    // AI has already opened. Run board-rearrangement backtracking search.
    final boardTiles = currentBoard.allTiles;
    final allTiles = [...boardTiles, ...hand];

    // Find all possible valid melds that can be made from the union of board and hand
    final allPossibleMelds = AIHelper.findAllPossibleMelds(allTiles);

    // Map each tile ID to the melds containing it for quick lookup
    final Map<String, List<Meld>> tileToMelds = {};
    for (var meld in allPossibleMelds) {
      for (var tile in meld.tiles) {
        tileToMelds.putIfAbsent(tile.id, () => []).add(meld);
      }
    }

    final Set<String> boardTileIds = boardTiles.map((t) => t.id).toSet();
    final Set<String> handTileIds = hand.map((t) => t.id).toSet();

    // Track search state
    _searchSteps = 0;
    List<Meld> bestCombination = [];
    int maxHandTilesPlayed = 0;

    void backtrack(
      Set<String> uncoveredBoard,
      Set<String> available,
      List<Meld> currentSelection,
    ) {
      _searchSteps++;
      if (_searchSteps > maxSearchSteps) return;

      if (uncoveredBoard.isEmpty) {
        // All board tiles are covered. We have a valid configuration.
        // Let's try to add even more disjoint melds using only remaining hand tiles.
        int handPlayed = handTileIds.length - handTileIds.intersection(available).length;

        // Perform a greedy search on remaining hand tiles to add any extra independent melds
        final remainingHandTiles = hand.where((t) => available.contains(t.id)).toList();
        final extraMelds = AIHelper.findDisjointMeldCombinations(remainingHandTiles);

        List<Meld> fullSelection = List.from(currentSelection);
        if (extraMelds.isNotEmpty) {
          // Sort to find the combination of extra melds that plays the most tiles
          extraMelds.sort((a, b) {
            final lenA = a.fold(0, (sum, m) => sum + m.tiles.length);
            final lenB = b.fold(0, (sum, m) => sum + m.tiles.length);
            return lenB.compareTo(lenA);
          });
          final bestExtra = extraMelds.first;
          fullSelection.addAll(bestExtra);
          handPlayed += bestExtra.fold(0, (sum, m) => sum + m.tiles.length);
        }

        if (handPlayed > maxHandTilesPlayed) {
          maxHandTilesPlayed = handPlayed;
          bestCombination = fullSelection;
        }
        return;
      }

      // Select an uncovered board tile to cover.
      // Heuristic: choose the tile that appears in the fewest compatible melds to minimize branching factor.
      String? bestTileId;
      int minMeldCount = 999999;
      List<Meld> bestCompatibleMelds = [];

      for (var tileId in uncoveredBoard) {
        final melds = tileToMelds[tileId] ?? [];
        // Filter melds that contain only currently available tiles
        final compatible = melds.where((m) {
          return m.tiles.every((t) => available.contains(t.id));
        }).toList();

        if (compatible.length < minMeldCount) {
          minMeldCount = compatible.length;
          bestTileId = tileId;
          bestCompatibleMelds = compatible;
        }
      }

      if (bestTileId == null || minMeldCount == 0) {
        // Dead end: an uncovered board tile cannot be covered
        return;
      }

      // Try covering the selected tile with each compatible meld
      for (var meld in bestCompatibleMelds) {
        // Double check all tiles in meld are available
        if (meld.tiles.every((t) => available.contains(t.id))) {
          final meldTileIds = meld.tiles.map((t) => t.id).toSet();

          // Action
          final nextUncovered = uncoveredBoard.difference(meldTileIds);
          final nextAvailable = available.difference(meldTileIds);
          currentSelection.add(meld);

          // Recurse
          backtrack(nextUncovered, nextAvailable, currentSelection);

          // Undo
          currentSelection.removeLast();
        }
      }
    }

    // Run the search
    final initialAvailable = allTiles.map((t) => t.id).toSet();
    backtrack(boardTileIds, initialAvailable, []);

    // If we managed to play at least one hand tile, return the configuration
    if (maxHandTilesPlayed > 0 && bestCombination.isNotEmpty) {
      final finalBoardMelds = bestCombination;
      final playedIds = finalBoardMelds.expand((m) => m.tiles).map((t) => t.id).toSet();
      final remainingHand = hand.where((tile) => !playedIds.contains(tile.id)).toList();

      return MapEntry(Board(melds: finalBoardMelds), remainingHand);
    }

    return null; // Draw a tile
  }

  MapEntry<Board, List<Tile>> _applyMeldsToBoard(
    Board currentBoard,
    List<Tile> hand,
    List<Meld> newMelds,
  ) {
    final updatedMelds = List<Meld>.from(currentBoard.melds)..addAll(newMelds);
    final nextBoard = currentBoard.copyWith(melds: updatedMelds);

    final playedIds = newMelds.expand((m) => m.tiles).map((t) => t.id).toSet();
    final nextHand = hand.where((tile) => !playedIds.contains(tile.id)).toList();

    return MapEntry(nextBoard, nextHand);
  }
}
