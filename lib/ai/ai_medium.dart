import '../models/tile.dart';
import '../models/meld.dart';
import '../models/board.dart';
import 'ai_base.dart';
import 'ai_helper.dart';

class AIMedium extends AIBase {
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

      // Pick the opening that plays the most tiles (or highest points)
      validOpenings.sort((a, b) {
        final ptsA = a.fold(0, (sum, m) => sum + m.points);
        final ptsB = b.fold(0, (sum, m) => sum + m.points);
        return ptsB.compareTo(ptsA);
      });

      final chosenComb = validOpenings.first;
      return _applyMeldsToBoard(currentBoard, hand, chosenComb);
    } else {
      // 1. Play new melds from hand
      final combinations = AIHelper.findDisjointMeldCombinations(hand);
      List<Meld> chosenComb = [];
      if (combinations.isNotEmpty) {
        combinations.sort((a, b) {
          final tilesA = a.fold(0, (sum, m) => sum + m.tiles.length);
          final tilesB = b.fold(0, (sum, m) => sum + m.tiles.length);
          return tilesB.compareTo(tilesA);
        });
        chosenComb = combinations.first;
      }

      // Compute board and hand after playing new melds
      final playedIds = chosenComb.expand((m) => m.tiles).map((t) => t.id).toSet();
      List<Tile> tempHand = hand.where((t) => !playedIds.contains(t.id)).toList();
      List<Meld> tempMelds = List<Meld>.from(currentBoard.melds)..addAll(chosenComb);

      // 2. Try appending remaining hand tiles to existing melds on the board
      bool tileAppended = true;
      while (tileAppended && tempHand.isNotEmpty) {
        tileAppended = false;

        for (int i = 0; i < tempHand.length; i++) {
          final tile = tempHand[i];

          // Try to append 'tile' to any meld in tempMelds
          for (int j = 0; j < tempMelds.length; j++) {
            final meld = tempMelds[j];

            // Try inserting at start, end, or middle
            for (int k = 0; k <= meld.tiles.length; k++) {
              final newTiles = List<Tile>.from(meld.tiles)..insert(k, tile);
              final testMeld = Meld(newTiles);

              if (testMeld.isValid) {
                // Found a valid append!
                tempMelds[j] = testMeld;
                tempHand.removeAt(i);
                tileAppended = true;
                break;
              }
            }

            if (tileAppended) break;
          }

          if (tileAppended) break;
        }
      }

      // Check if we actually made any plays
      final totalPlayed = hand.length - tempHand.length;
      if (totalPlayed == 0) {
        return null;
      }

      return MapEntry(Board(melds: tempMelds), tempHand);
    }
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
